@IsTest
private class AppointmentControllerTest {

    private static final String SPEC_KEY   = 'Cardiology';
    private static final String CAL_ID     = 'cal123@group.calendar.google.com';
    private static final String START_ISO  = '2026-03-21T09:00:00';
    private static final String END_ISO    = '2026-03-21T10:00:00';
    private static final String TZ         = 'Europe/London';
    private static final String EVENT_JSON =
        '{"id":"gcal001","htmlLink":"https://calendar.google.com/event?eid=gcal001"}';

    @IsTest
    static void getSpecializations_returnsNonNullList() {
        Test.startTest();
        List<Specialization__mdt> specs = AppointmentController.getSpecializations();
        Test.stopTest();

        Assert.isNotNull(specs, 'Should return a non-null list of specializations');
    }

    @IsTest
    static void getPatientRecordTypeId_returnsValidId() {
        Test.startTest();
        Id rtId = AppointmentController.getPatientRecordTypeId();
        Test.stopTest();

        Assert.isNotNull(rtId, 'Should return the Patient record type Id');
        Assert.areEqual(TestDataFactory.getPatientRecordTypeId(), rtId);
    }

    @IsTest
    static void getDoctorsBySpecialization_returnsMatchingDoctors() {
        Contact doc = TestDataFactory.createDoctor(true);

        Test.startTest();
        List<Contact> result = AppointmentController.getDoctorsBySpecialization(SPEC_KEY);
        Test.stopTest();

        Assert.isNotNull(result);
        Boolean found = false;
        for (Contact c : result) {
            if (c.Id == doc.Id) { found = true; break; }
        }
        Assert.isTrue(found, 'Inserted doctor should appear in results');
    }

    @IsTest
    static void getDoctorsBySpecialization_noMatch_returnsEmptyList() {
        Test.startTest();
        List<Contact> result = AppointmentController.getDoctorsBySpecialization('NonExistentSpecialization');
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual(0, result.size(), 'Expected empty list for unknown specialization');
    }

    @IsTest
    static void getDoctorsBySpecialization_blankValue_throwsAura() {
        Exception caught;
        try {
            AppointmentController.getDoctorsBySpecialization('');
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught, 'Should throw for blank specialization');
        Assert.isTrue(caught.getMessage().contains('Specialization'));
    }

    @IsTest
    static void getDoctorsBySpecialization_nullValue_throwsAura() {
        Exception caught;
        try {
            AppointmentController.getDoctorsBySpecialization(null);
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught, 'Should throw for null specialization');
    }

    @IsTest
    static void createAppointment_nullDoctorId_throws() {
        Id patId = TestDataFactory.createPatient(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                null, patId, SPEC_KEY, 200, CAL_ID, START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Doctor'));
    }

    @IsTest
    static void createAppointment_nullPatientId_throws() {
        Id docId = TestDataFactory.createDoctor(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                docId, null, SPEC_KEY, 200, CAL_ID, START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Patient'));
    }

    @IsTest
    static void createAppointment_blankCalendarId_throws() {
        Id docId = TestDataFactory.createDoctor(true).Id;
        Id patId = TestDataFactory.createPatient(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                docId, patId, SPEC_KEY, 200, '', START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @IsTest
    static void createAppointment_blankStartTime_throws() {
        Id docId = TestDataFactory.createDoctor(true).Id;
        Id patId = TestDataFactory.createPatient(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                docId, patId, SPEC_KEY, 200, CAL_ID, '', END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Start time'));
    }

    @IsTest
    static void createAppointment_blankEndTime_throws() {
        Id docId = TestDataFactory.createDoctor(true).Id;
        Id patId = TestDataFactory.createPatient(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                docId, patId, SPEC_KEY, 200, CAL_ID, START_ISO, '', TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('End time'));
    }

    @IsTest
    static void createAppointment_blankSpecialization_throws() {
        Id docId = TestDataFactory.createDoctor(true).Id;
        Id patId = TestDataFactory.createPatient(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                docId, patId, '', 200, CAL_ID, START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Specialization'));
    }

    @IsTest
    static void createAppointment_success_insertsRecordAndReturnsId() {
        Contact doc = TestDataFactory.createDoctor(true);
        Contact pat = TestDataFactory.createPatient(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, EVENT_JSON));

        Test.startTest();
        Id apptId = AppointmentController.createAppointment(
            doc.Id, pat.Id, SPEC_KEY, 200, CAL_ID, START_ISO, END_ISO, TZ, 'Test notes'
        );
        Test.stopTest();

        Assert.isNotNull(apptId, 'Should return the new Appointment__c Id');

        Appointment__c created = [
            SELECT Status__c, Price__c, Google_Calendar_Event_Id__c,
                   Doctor__c, Patient__c, Notes__c,
                   Specialization__c
            FROM   Appointment__c
            WHERE  Id = :apptId
        ];

        Assert.areEqual('Scheduled', created.Status__c);
        Assert.areEqual(200,         created.Price__c);
        Assert.areEqual('gcal001',   created.Google_Calendar_Event_Id__c);
        Assert.areEqual(doc.Id,      created.Doctor__c);
        Assert.areEqual(pat.Id,      created.Patient__c);
        Assert.areEqual('Test notes',created.Notes__c);
        Assert.areEqual(SPEC_KEY,    created.Specialization__c);
    }

    @IsTest
    static void createAppointment_blankTimezone_defaultsToEuropeLondon() {
        Contact doc = TestDataFactory.createDoctor(true);
        Contact pat = TestDataFactory.createPatient(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, EVENT_JSON));

        Test.startTest();
        Id apptId = AppointmentController.createAppointment(
            doc.Id, pat.Id, SPEC_KEY, 150, CAL_ID, START_ISO, END_ISO, null, null
        );
        Test.stopTest();

        Assert.isNotNull(apptId, 'Blank timezone should fall back to Europe/London and succeed');
    }

    @IsTest
    static void createAppointment_gcalError_throwsAura() {
        Contact doc = TestDataFactory.createDoctor(true);
        Contact pat = TestDataFactory.createPatient(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(403,
            '{"error":{"code":403,"message":"Forbidden","errors":[{"reason":"forbidden"}]}}'));

        Exception caught;
        Test.startTest();
        try {
            AppointmentController.createAppointment(
                doc.Id, pat.Id, SPEC_KEY, 200, CAL_ID, START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Test.stopTest();

        Assert.isNotNull(caught, 'Should propagate Google Calendar API error as AuraHandledException');
    }

    @IsTest
    static void createAppointment_doctorDeletedBeforeBooking_throwsAura() {
        Contact doc = TestDataFactory.createDoctor(true);
        Id docId    = doc.Id;
        delete doc;

        Id patId = TestDataFactory.createPatient(true).Id;
        Exception caught;
        try {
            AppointmentController.createAppointment(
                docId, patId, SPEC_KEY, 200, CAL_ID, START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) { caught = ex; }

        Assert.isNotNull(caught, 'QueryException should be caught and rethrown as AuraHandledException');
        Assert.isTrue(caught.getMessage().contains('Failed to create appointment'));
    }

    @IsTest
    static void createAppointment_noAppointmentInsertedOnGcalError() {
        Contact doc = TestDataFactory.createDoctor(true);
        Contact pat = TestDataFactory.createPatient(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(500,
            '{"error":{"code":500,"message":"Internal Server Error"}}'));

        Test.startTest();
        try {
            AppointmentController.createAppointment(
                doc.Id, pat.Id, SPEC_KEY, 200, CAL_ID, START_ISO, END_ISO, TZ, null
            );
        } catch (AuraHandledException ex) {}
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Appointment__c WHERE Doctor__c = :doc.Id];
        Assert.areEqual(0, count, 'No Appointment__c record should be created when Google Calendar call fails');
    }
}
