public with sharing class GoogleCalendarController {

    @AuraEnabled
    public static String createCalendarEvent(GoogleCalendarModels.CreateEventInput input) {
        try {
            GoogleCalendarControllerHelper.validateCreateEventInputs(input);
            DateTime startDt = Utils.parseIsoDateTime(input.startIso);
            DateTime endDt = Utils.parseIsoDateTime(input.endIso);
            GoogleCalendarControllerHelper.validateTimeWindow(startDt, endDt);
            return GoogleCalendarControllerHelper.orchestrateCreateEvent(input, startDt, endDt);
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
