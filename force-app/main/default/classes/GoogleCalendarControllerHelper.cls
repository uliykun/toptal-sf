public with sharing class GoogleCalendarControllerHelper {

    public static void validateCreateEventInputs(
            String calendarId,
            String patientName,
            String physicianName,
            String specialization,
            String startIso,
            String endIso,
            String timeZone) {

        Utils.validateAllNotBlank(new Map<String, String>{
            'Calendar ID' => calendarId,
            'Patient name' => patientName,
            'Physician name' => physicianName,
            'Specialization' => specialization,
            'Appointment start' => startIso,
            'Appointment end' => endIso,
            'Timezone' => timeZone
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
            String calendarId,
            String patientName,
            String physicianName,
            String specialization,
            DateTime startDt,
            DateTime endDt,
            String timeZone,
            String patientEmail) {

        GoogleCalendarModels.EventRequest request = GoogleCalendarService.buildEventRequest(
            patientName, physicianName, specialization, startDt, endDt, timeZone, patientEmail
        );
        GoogleCalendarModels.EventResponse response =
            GoogleCalendarService.createAppointmentEvent(calendarId, request);
        return response.htmlLink;
    }
}
