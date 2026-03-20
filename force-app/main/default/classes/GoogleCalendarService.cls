public with sharing class GoogleCalendarService {

    @TestVisible private static final String  NAMED_CREDENTIAL  = 'Google_Calendar_API';
    @TestVisible private static final String  DEFAULT_TIMEZONE  = 'UTC';
    @TestVisible static final Integer WORK_START_HOUR           = 9;
    @TestVisible static final Integer WORK_END_HOUR             = 17;
    @TestVisible static final Integer SLOT_DURATION_MIN         = 30;

    private static final String  EVENTS_PATH          = '/calendar/v3/calendars/{0}/events';
    private static final String  EVENT_RESOURCE_PATH  = '/calendar/v3/calendars/{0}/events/{1}';
    private static final Integer TIMEOUT_MS           = 20000;

    public static GoogleCalendarModels.EventResponse createAppointmentEvent(
            String calendarId,
            GoogleCalendarModels.EventRequest request) {

        Utils.validateNotBlank(calendarId, 'Calendar ID');
        if (request == null) {
            Utils.throwHandled('Event request cannot be null.');
        }
        return parseAndAssertSuccess(callCreateEvent(calendarId, request.toJsonBody()));
    }

    public static String listEventsRaw(
            String calendarId,
            String timeMinUtc,
            String timeMaxUtc) {

        Utils.validateNotBlank(calendarId, 'Calendar ID');
        Utils.validateNotBlank(timeMinUtc, 'timeMin');
        Utils.validateNotBlank(timeMaxUtc, 'timeMax');

        String queryParams = 'timeMin=' + EncodingUtil.urlEncode(timeMinUtc, 'UTF-8')
            + '&timeMax='     + EncodingUtil.urlEncode(timeMaxUtc, 'UTF-8')
            + '&singleEvents=true&orderBy=startTime';

        HttpUtils.ResponseWrapper raw = callListEvents(calendarId, queryParams);
        if (!raw.isSuccess) {
            String apiMsg = tryExtractGoogleError(raw.responseBody);
            Utils.throwHandled(String.isNotBlank(apiMsg)
                ? 'Could not fetch calendar events: ' + apiMsg
                : 'Could not fetch calendar events: ' + raw.errorMessage);
        }
        return raw.responseBody;
    }

    public static GoogleCalendarModels.EventResponse patchAppointmentEvent(
            String calendarId,
            String eventId,
            String patchJsonBody) {

        Utils.validateNotBlank(calendarId,    'Calendar ID');
        Utils.validateNotBlank(eventId,       'Event ID');
        Utils.validateNotBlank(patchJsonBody, 'Patch body');
        return parseAndAssertSuccess(callPatchEvent(calendarId, eventId, patchJsonBody));
    }

    public static GoogleCalendarModels.EventRequest buildEventRequest(
            String   patientName,
            String   physicianName,
            String   specialization,
            DateTime startDt,
            DateTime endDt,
            String   timeZone,
            String   patientEmail) {

        String tz   = String.isNotBlank(timeZone) ? timeZone : DEFAULT_TIMEZONE;
        GoogleCalendarModels.EventRequest request = new GoogleCalendarModels.EventRequest(
            buildSummary(specialization, patientName),
            buildDescription(patientName, physicianName, specialization),
            startDt, endDt, tz
        );
        request.addAttendee(patientEmail);
        return request;
    }

    public static List<GoogleCalendarModels.TimeSlot> getAvailableSlots(
            String calendarId,
            String dateStr,
            String timeZone) {

        Utils.validateNotBlank(calendarId, 'Calendar ID');
        Utils.validateNotBlank(dateStr,    'Date');
        Utils.validateNotBlank(timeZone,   'Timezone');

        Date d = Date.valueOf(dateStr);

        DateTime workStartProxy = DateTime.newInstanceGmt(d.year(), d.month(), d.day(), WORK_START_HOUR, 0, 0);
        DateTime workEndProxy   = DateTime.newInstanceGmt(d.year(), d.month(), d.day(), WORK_END_HOUR,   0, 0);

        System.Timezone tz = System.Timezone.getTimeZone(timeZone);
        DateTime workStartUtc = workStartProxy.addSeconds(-tz.getOffset(workStartProxy) / 1000);
        DateTime workEndUtc   = workEndProxy.addSeconds(  -tz.getOffset(workEndProxy)   / 1000);

        String timeMin = workStartUtc.format('yyyy-MM-dd\'T\'HH:mm:ss') + 'Z';
        String timeMax = workEndUtc.format('yyyy-MM-dd\'T\'HH:mm:ss')   + 'Z';

        String rawJson = listEventsRaw(calendarId, timeMin, timeMax);
        List<BusyRange> busyRanges = extractBusyRanges(rawJson);
        return buildSlots(workStartUtc, workEndUtc, timeZone, busyRanges);
    }

    private static List<BusyRange> extractBusyRanges(String rawJson) {
        List<BusyRange> ranges = new List<BusyRange>();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
        List<Object> items = (List<Object>) parsed.get('items');
        if (items == null || items.isEmpty()) return ranges;

        for (Object item : items) {
            Map<String, Object> evt      = (Map<String, Object>) item;
            Map<String, Object> startObj = (Map<String, Object>) evt.get('start');
            Map<String, Object> endObj   = (Map<String, Object>) evt.get('end');
            if (startObj == null || endObj == null) continue;

            String startStr = (String) startObj.get('dateTime');
            String endStr   = (String) endObj.get('dateTime');
            if (String.isBlank(startStr) || String.isBlank(endStr)) continue;

            DateTime evtStart = parseGoogleDateTime(startStr);
            DateTime evtEnd   = parseGoogleDateTime(endStr);
            if (evtStart == null || evtEnd == null) continue;

            ranges.add(new BusyRange(evtStart.getTime(), evtEnd.getTime()));
        }
        return ranges;
    }

    @TestVisible
    private static DateTime parseGoogleDateTime(String s) {
        try {
            if (s.endsWith('Z')) {
                return DateTime.valueOf(s.removeEnd('Z').replace('T', ' '));
            }
            Integer plusIdx  = s.lastIndexOf('+');
            Integer minusIdx = s.lastIndexOf('-');
            Integer signIdx  = (plusIdx  > 10) ? plusIdx  : ((minusIdx > 10) ? minusIdx : -1);
            if (signIdx > 0) {
                Integer sign          = (s.substring(signIdx, signIdx + 1) == '+') ? 1 : -1;
                Integer offsetHours   = Integer.valueOf(s.substring(signIdx + 1, signIdx + 3));
                Integer offsetMinutes = Integer.valueOf(s.substring(signIdx + 4, signIdx + 6));
                Integer offsetSeconds = (offsetHours * 60 + offsetMinutes) * 60 * sign;
                DateTime base = DateTime.valueOf(s.substring(0, signIdx).replace('T', ' '));
                return base.addSeconds(-offsetSeconds);
            }
            return DateTime.valueOf(s.replace('T', ' '));
        } catch (Exception ex) {
            return null;
        }
    }

    private static List<GoogleCalendarModels.TimeSlot> buildSlots(
            DateTime workStartUtc,
            DateTime workEndUtc,
            String   timeZone,
            List<BusyRange> busyRanges) {

        List<GoogleCalendarModels.TimeSlot> slots = new List<GoogleCalendarModels.TimeSlot>();
        DateTime current = workStartUtc;
        while (current < workEndUtc) {
            DateTime slotEnd  = current.addMinutes(SLOT_DURATION_MIN);
            Boolean available = !isSlotBusy(current.getTime(), slotEnd.getTime(), busyRanges);
            slots.add(new GoogleCalendarModels.TimeSlot(current, slotEnd, timeZone, available));
            current = slotEnd;
        }
        return slots;
    }

    private static Boolean isSlotBusy(Long slotStartMs, Long slotEndMs, List<BusyRange> busyRanges) {
        for (BusyRange r : busyRanges) {
            if (slotStartMs < r.endMs && slotEndMs > r.startMs) return true;
        }
        return false;
    }

    private static GoogleCalendarModels.EventResponse parseAndAssertSuccess(
            HttpUtils.ResponseWrapper raw) {

        if (!raw.isSuccess) {
            String apiMsg = tryExtractGoogleError(raw.responseBody);
            Utils.throwHandled(String.isNotBlank(apiMsg)
                ? 'Google Calendar API error: ' + apiMsg
                : 'Google Calendar API error: ' + raw.errorMessage);
        }
        try {
            GoogleCalendarModels.EventResponse response =
                GoogleCalendarModels.parseEventResponse(raw.responseBody);
            if (String.isBlank(response.id)) {
                Utils.throwHandled(
                    'Google Calendar returned an empty event ID. '
                    + 'The event may not have been created.'
                );
            }
            return response;
        } catch (System.JSONException ex) {
            Utils.throwHandled('Failed to parse Google Calendar response: ' + ex.getMessage());
            return null;
        }
    }

    private static String tryExtractGoogleError(String responseBody) {
        if (String.isBlank(responseBody)) return null;
        try {
            return GoogleCalendarModels.parseEventResponse(responseBody).getErrorMessage();
        } catch (Exception ex) {
            return null;
        }
    }

    private static String buildSummary(String specialization, String patientName) {
        return specialization + ' Appointment — ' + patientName;
    }

    private static String buildDescription(
            String patientName, String physicianName, String specialization) {
        return 'Patient: '        + patientName   + '\n'
             + 'Physician: Dr. '  + physicianName + '\n'
             + 'Specialization: ' + specialization;
    }

    private static HttpUtils.ResponseWrapper callCreateEvent(String calendarId, String jsonBody) {
        return HttpUtils.send(HttpUtils.buildJsonRequest(
            'POST', buildEndpoint(EVENTS_PATH, new List<String>{ calendarId }), jsonBody, TIMEOUT_MS
        ));
    }

    private static HttpUtils.ResponseWrapper callListEvents(String calendarId, String queryParams) {
        String path = buildEndpoint(EVENTS_PATH, new List<String>{ calendarId });
        if (String.isNotBlank(queryParams)) path += '?' + queryParams;
        return HttpUtils.send(HttpUtils.buildRequest('GET', path, TIMEOUT_MS));
    }

    private static HttpUtils.ResponseWrapper callPatchEvent(
            String calendarId, String eventId, String jsonBody) {
        return HttpUtils.send(HttpUtils.buildJsonRequest(
            'PATCH',
            buildEndpoint(EVENT_RESOURCE_PATH, new List<String>{ calendarId, eventId }),
            jsonBody, TIMEOUT_MS
        ));
    }

    private static String buildEndpoint(String pathTemplate, List<String> args) {
        return 'callout:' + NAMED_CREDENTIAL + String.format(pathTemplate, args);
    }

    private class BusyRange {
        Long startMs;
        Long endMs;
        BusyRange(Long s, Long e) { startMs = s; endMs = e; }
    }
}
