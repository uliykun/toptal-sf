public with sharing class AppointmentController {

    /**
     * Returns all Specialization custom metadata records ordered alphabetically.
     * Cacheable — safe to wire directly in LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<Specialization__mdt> getSpecializations() {
        try {
            return [
                SELECT Id, MasterLabel, DeveloperName, Price__c
                FROM   Specialization__mdt
                ORDER BY MasterLabel ASC
            ];
        } catch (Exception ex) {
            Utils.throwHandled('Could not load specializations: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * Returns the Id of the Patient Contact record type.
     * Used by the LWC record-picker filter (which requires RecordTypeId, not DeveloperName).
     * Cacheable — safe to wire directly in LWC.
     */
    @AuraEnabled(cacheable=true)
    public static Id getPatientRecordTypeId() {
        try {
            return [
                SELECT Id FROM RecordType
                WHERE  SObjectType    = 'Contact'
                AND    DeveloperName  = 'Patient'
                LIMIT  1
            ].Id;
        } catch (Exception ex) {
            Utils.throwHandled('Could not load Patient record type: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * Returns Doctor contacts for a given specialization.
     * Only returns doctors who have a Google Calendar ID configured.
     * Cacheable — safe to wire directly in LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getDoctorsBySpecialization(String specialization) {
        Utils.validateNotBlank(specialization, 'Specialization');
        try {
            return [
                SELECT Id, FirstName, LastName, Title, Email,
                       Specialization__c, Google_Calendar_Id__c
                FROM   Contact
                WHERE  RecordType.DeveloperName  = 'Doctor'
                AND    Specialization__c          = :specialization
                AND    Google_Calendar_Id__c     != null
                ORDER BY LastName ASC
            ];
        } catch (Exception ex) {
            Utils.throwHandled('Could not load doctors: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * Creates an Appointment__c record and a matching Google Calendar event atomically.
     * Converts the local ISO times to UTC using the supplied timezone before persisting.
     */
    @AuraEnabled
    public static Id createAppointment(
            Id      doctorId,
            Id      patientId,
            String  specialization,
            Decimal price,
            String  calendarId,
            String  startIso,
            String  endIso,
            String  timeZone,
            String  notes) {

        if (doctorId  == null) Utils.throwHandled('Doctor is required.');
        if (patientId == null) Utils.throwHandled('Patient is required.');
        Utils.validateNotBlank(calendarId,    'Calendar ID');
        Utils.validateNotBlank(startIso,      'Start time');
        Utils.validateNotBlank(endIso,        'End time');
        Utils.validateNotBlank(specialization,'Specialization');

        try {
            String tz = String.isNotBlank(timeZone) ? timeZone : 'Europe/London';

            // Fetch doctor and patient names for the calendar event title/description
            Contact doctor  = [SELECT FirstName, LastName FROM Contact WHERE Id = :doctorId  LIMIT 1];
            Contact patient = [SELECT FirstName, LastName, Email FROM Contact WHERE Id = :patientId LIMIT 1];

            // Parse local ISO strings and convert to true UTC using the timezone offset
            DateTime startProxy = Utils.parseIsoDateTime(startIso);
            DateTime endProxy   = Utils.parseIsoDateTime(endIso);
            System.Timezone tzObj = System.Timezone.getTimeZone(tz);
            DateTime startUtc = startProxy.addSeconds(-tzObj.getOffset(startProxy) / 1000);
            DateTime endUtc   = endProxy.addSeconds(  -tzObj.getOffset(endProxy)   / 1000);

            // Create Google Calendar event
            String patientName = patient.FirstName + ' ' + patient.LastName;
            String doctorName  = doctor.FirstName  + ' ' + doctor.LastName;
            GoogleCalendarModels.EventRequest request = GoogleCalendarService.buildEventRequest(
                patientName, doctorName, specialization, startUtc, endUtc, tz, patient.Email
            );
            GoogleCalendarModels.EventResponse gcalResp =
                GoogleCalendarService.createAppointmentEvent(calendarId, request);

            // Persist Appointment record
            Appointment__c appt = new Appointment__c(
                Doctor__c                   = doctorId,
                Patient__c                  = patientId,
                Specialization__c           = specialization,
                Price__c                    = price,
                Start_Time__c               = startUtc,
                End_Time__c                 = endUtc,
                Google_Calendar_Event_Id__c = gcalResp.id,
                Status__c                   = 'Scheduled',
                Notes__c                    = notes
            );
            insert appt;
            return appt.Id;

        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'AppointmentController.createAppointment error: '
                + ex.getMessage() + '\n' + ex.getStackTraceString());
            Utils.throwHandled('Failed to create appointment: ' + ex.getMessage());
            return null;
        }
    }
}
