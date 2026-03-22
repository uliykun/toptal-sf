public with sharing class GoogleCalendarControllerHelper {

    public static void validateCreateEventInputs(GoogleCalendarModels.CreateEventInput input) {
        Utils.validateAllNotBlank(new Map<String, String>{
            'Calendar ID' => input.calendarId,
            'Patient name' => input.patientName,
            'Physician name' => input.physicianName,
            'Specialization' => input.specialization,
            'Appointment start' => input.startIso,
            'Appointment end' => input.endIso,
            'Timezone' => input.timeZone
        });
    }

    public static void validateTimeWindow(DateTime startDt, DateTime endDt) {
        if (endDt <= startDt) {
            Utils.throwHandled('Appointment end time must be after start time.');
        }
    }

    public static List<GoogleCalendarModels.TimeSlot> orchestrateGetSlots(
            String calendarId,
            String dateStr,
            String timeZone) {
        return GoogleCalendarService.getAvailableSlots(calendarId, dateStr, timeZone);
    }

    public static String orchestrateCreateEvent(
            GoogleCalendarModels.CreateEventInput input,
            DateTime startDt,
            DateTime endDt) {

        GoogleCalendarModels.EventRequest request = GoogleCalendarService.buildEventRequest(
            input.patientName, input.physicianName, input.specialization,
            startDt, endDt, input.timeZone, input.patientEmail
        );
        GoogleCalendarModels.EventResponse response =
            GoogleCalendarService.createAppointmentEvent(input.calendarId, request);
        return response.htmlLink;
    }
}
