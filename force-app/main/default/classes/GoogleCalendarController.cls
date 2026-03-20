public with sharing class GoogleCalendarController {

    @AuraEnabled
    public static String createCalendarEvent(
            String calendarId,
            String patientName,
            String physicianName,
            String specialization,
            String startIso,
            String endIso,
            String timeZone,
            String patientEmail) {
        try {
            GoogleCalendarControllerHelper.validateCreateEventInputs(
                calendarId, patientName, physicianName,
                specialization, startIso, endIso, timeZone
            );
            DateTime startDt = Utils.parseIsoDateTime(startIso);
            DateTime endDt   = Utils.parseIsoDateTime(endIso);
            GoogleCalendarControllerHelper.validateTimeWindow(startDt, endDt);
            return GoogleCalendarControllerHelper.orchestrateCreateEvent(
                calendarId, patientName, physicianName, specialization,
                startDt, endDt, timeZone, patientEmail
            );
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'GoogleCalendarController.createCalendarEvent unexpected error: '
                + ex.getMessage() + '\n' + ex.getStackTraceString());
            throw new AuraHandledException(
                'An unexpected error occurred while creating the calendar event. '
                + 'Please contact your administrator.'
            );
        }
    }

    @AuraEnabled
    public static List<GoogleCalendarModels.TimeSlot> getAvailableSlots(
            String calendarId,
            String dateStr,
            String timeZone) {
        try {
            return GoogleCalendarControllerHelper.orchestrateGetSlots(calendarId, dateStr, timeZone);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'GoogleCalendarController.getAvailableSlots unexpected error: '
                + ex.getMessage() + '\n' + ex.getStackTraceString());
            throw new AuraHandledException(
                'An unexpected error occurred while fetching available slots. '
                + 'Please contact your administrator.'
            );
        }
    }

    @AuraEnabled
    public static String getCalendarEvents(
            String calendarId,
            String timeMinUtc,
            String timeMaxUtc) {
        try {
            return GoogleCalendarService.listEventsRaw(calendarId, timeMinUtc, timeMaxUtc);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'GoogleCalendarController.getCalendarEvents unexpected error: '
                + ex.getMessage() + '\n' + ex.getStackTraceString());
            throw new AuraHandledException(
                'An unexpected error occurred while fetching calendar events. '
                + 'Please contact your administrator.'
            );
        }
    }
}
