@isTest
private class GoogleCalendarServiceTest {

    private static final String CAL_ID = 'primary';
    private static final String EVENT_ID = 'evt123';
    private static final String VALID_JSON =
        '{"id":"evt1","status":"confirmed","htmlLink":"https://cal.google.com/event/evt1"}';


    @isTest
    static void createAppointmentEvent_success_returnsResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, VALID_JSON));
        Test.startTest();
        GoogleCalendarModels.EventResponse resp =
            GoogleCalendarService.createAppointmentEvent(CAL_ID, makeRequest());
        Test.stopTest();
        Assert.areEqual('evt1', resp.id);
    }

    @isTest
    static void createAppointmentEvent_blankCalendarId_throws() {
        Exception caught;
        try {
            GoogleCalendarService.createAppointmentEvent('', makeRequest());
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void createAppointmentEvent_nullRequest_throws() {
        Exception caught;
        try {
            GoogleCalendarService.createAppointmentEvent(CAL_ID, null);
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('null'));
    }

    @isTest
    static void createAppointmentEvent_apiError_throwsWithGoogleMessage() {
        Test.setMock(HttpCalloutMock.class,
            new MockHttpCallout(403, '{"error":{"code":403,"message":"Forbidden"}}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.createAppointmentEvent(CAL_ID, makeRequest());
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Forbidden'));
    }

    @isTest
    static void createAppointmentEvent_nonParseableErrorBody_fallsBackToHttpError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(403, '{corrupt}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.createAppointmentEvent(CAL_ID, makeRequest());
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('403'));
    }

    @isTest
    static void createAppointmentEvent_calloutException_throws() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(true));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.createAppointmentEvent(CAL_ID, makeRequest());
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Callout failed'));
    }

    @isTest
    static void createAppointmentEvent_emptyEventId_throws() {
        Test.setMock(HttpCalloutMock.class,
            new MockHttpCallout(200, '{"status":"confirmed"}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.createAppointmentEvent(CAL_ID, makeRequest());
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('empty event ID'));
    }

    @isTest
    static void createAppointmentEvent_malformedResponseBody_throws() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{bad json'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.createAppointmentEvent(CAL_ID, makeRequest());
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('parse'));
    }


    @isTest
    static void listEventsRaw_success_returnsBody() {
        String rawJson = '{"items":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, rawJson));
        Test.startTest();
        String result = GoogleCalendarService.listEventsRaw(
            CAL_ID, '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z');
        Test.stopTest();
        Assert.areEqual(rawJson, result);
    }

    @isTest
    static void listEventsRaw_blankCalendarId_throws() {
        Exception caught;
        try {
            GoogleCalendarService.listEventsRaw('', '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void listEventsRaw_blankTimeMin_throws() {
        Exception caught;
        try {
            GoogleCalendarService.listEventsRaw(CAL_ID, '', '2026-03-22T00:00:00Z');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('timeMin'));
    }

    @isTest
    static void listEventsRaw_blankTimeMax_throws() {
        Exception caught;
        try {
            GoogleCalendarService.listEventsRaw(CAL_ID, '2026-03-21T00:00:00Z', '');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('timeMax'));
    }

    @isTest
    static void listEventsRaw_apiError_throwsWithGoogleMessage() {
        Test.setMock(HttpCalloutMock.class,
            new MockHttpCallout(401, '{"error":{"code":401,"message":"Unauthorized"}}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.listEventsRaw(
                CAL_ID, '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z');
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Unauthorized'));
    }

    @isTest
    static void listEventsRaw_nonParseableErrorBody_fallsBackToHttpError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(400, '{corrupt}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarService.listEventsRaw(
                CAL_ID, '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z');
        } catch (Exception ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('400'));
    }


    @isTest
    static void patchAppointmentEvent_success_returnsResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, VALID_JSON));
        Test.startTest();
        GoogleCalendarModels.EventResponse resp =
            GoogleCalendarService.patchAppointmentEvent(CAL_ID, EVENT_ID, '{"summary":"Updated"}');
        Test.stopTest();
        Assert.areEqual('evt1', resp.id);
    }

    @isTest
    static void patchAppointmentEvent_blankCalendarId_throws() {
        Exception caught;
        try {
            GoogleCalendarService.patchAppointmentEvent('', EVENT_ID, '{}');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void patchAppointmentEvent_blankEventId_throws() {
        Exception caught;
        try {
            GoogleCalendarService.patchAppointmentEvent(CAL_ID, '', '{}');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Event ID'));
    }

    @isTest
    static void patchAppointmentEvent_blankBody_throws() {
        Exception caught;
        try {
            GoogleCalendarService.patchAppointmentEvent(CAL_ID, EVENT_ID, '');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Patch body'));
    }


    @isTest
    static void buildEventRequest_withAttendee_setsAllFields() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = GoogleCalendarService.buildEventRequest(
            'John Doe', 'Smith', 'Cardiology', start, endDt, 'UTC', 'john@example.com');
        Assert.isTrue(req.summary.contains('John Doe'));
        Assert.isTrue(req.description.contains('Dr. Smith'));
        Assert.areEqual(1, req.attendees.size());
        Assert.areEqual('john@example.com', req.attendees[0].email);
    }

    @isTest
    static void buildEventRequest_blankTimezone_defaultsToUtc() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = GoogleCalendarService.buildEventRequest(
            'Jane', 'Jones', 'Dermatology', start, endDt, '', null);
        Assert.areEqual(GoogleCalendarService.DEFAULT_TIMEZONE, req.start.timeZone);
    }

    @isTest
    static void buildEventRequest_blankEmail_zeroAttendees() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = GoogleCalendarService.buildEventRequest(
            'Jane', 'Jones', 'Dermatology', start, endDt, 'UTC', '');
        Assert.areEqual(0, req.attendees.size());
    }


    @isTest
    static void getAvailableSlots_blankCalendarId_throws() {
        Exception caught;
        try {
            GoogleCalendarService.getAvailableSlots('', '2026-03-21', 'UTC');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void getAvailableSlots_blankDate_throws() {
        Exception caught;
        try {
            GoogleCalendarService.getAvailableSlots(CAL_ID, '', 'UTC');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Date'));
    }

    @isTest
    static void getAvailableSlots_blankTimezone_throws() {
        Exception caught;
        try {
            GoogleCalendarService.getAvailableSlots(CAL_ID, '2026-03-21', '');
        } catch (Exception ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Timezone'));
    }

    @isTest
    static void getAvailableSlots_noEvents_allSlotsAvailable() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"items":[]}'));
        Test.startTest();
        List<GoogleCalendarModels.TimeSlot> slots =
            GoogleCalendarService.getAvailableSlots(CAL_ID, '2026-03-21', 'UTC');
        Test.stopTest();
        Integer expected = (GoogleCalendarService.WORK_END_HOUR - GoogleCalendarService.WORK_START_HOUR)
            * 60 / GoogleCalendarService.SLOT_DURATION_MIN;
        Assert.areEqual(expected, slots.size());
        for (GoogleCalendarModels.TimeSlot s : slots) {
            Assert.isTrue(s.isAvailable);
        }
    }

    @isTest
    static void getAvailableSlots_withBusyEvent_overlappingSlotsMarkedUnavailable() {
        String eventsJson = '{"items":[{"start":{"dateTime":"2026-03-21T10:00:00Z"},'
            + '"end":{"dateTime":"2026-03-21T11:00:00Z"}}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, eventsJson));
        Test.startTest();
        List<GoogleCalendarModels.TimeSlot> slots =
            GoogleCalendarService.getAvailableSlots(CAL_ID, '2026-03-21', 'UTC');
        Test.stopTest();
        Integer busyCount = 0;
        for (GoogleCalendarModels.TimeSlot s : slots) {
            if (!s.isAvailable) busyCount++;
        }
        Assert.areEqual(2, busyCount);
    }

    @isTest
    static void getAvailableSlots_withOffsetDateTime_parsedCorrectly() {
        String eventsJson = '{"items":[{"start":{"dateTime":"2026-03-21T10:00:00+01:00"},'
            + '"end":{"dateTime":"2026-03-21T11:00:00+01:00"}}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, eventsJson));
        Test.startTest();
        List<GoogleCalendarModels.TimeSlot> slots =
            GoogleCalendarService.getAvailableSlots(CAL_ID, '2026-03-21', 'UTC');
        Test.stopTest();
        Integer busyCount = 0;
        for (GoogleCalendarModels.TimeSlot s : slots) {
            if (!s.isAvailable) busyCount++;
        }
        Assert.areEqual(2, busyCount);
    }

    @isTest
    static void parseGoogleDateTime_zSuffix_returnsUtc() {
        DateTime result = GoogleCalendarService.parseGoogleDateTime('2026-03-21T10:00:00Z');
        Assert.isNotNull(result);
        Assert.areEqual(DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0), result);
    }

    @isTest
    static void parseGoogleDateTime_positiveOffset_convertsToUtc() {
        DateTime result = GoogleCalendarService.parseGoogleDateTime('2026-03-21T11:00:00+01:00');
        Assert.isNotNull(result);
        Assert.areEqual(DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0), result);
    }

    @isTest
    static void parseGoogleDateTime_negativeOffset_convertsToUtc() {
        DateTime result = GoogleCalendarService.parseGoogleDateTime('2026-03-21T05:00:00-05:00');
        Assert.isNotNull(result);
        Assert.areEqual(DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0), result);
    }

    @isTest
    static void parseGoogleDateTime_noOffset_returnsParsed() {
        DateTime result = GoogleCalendarService.parseGoogleDateTime('2026-03-21T10:00:00');
        Assert.isNotNull(result);
        Assert.areEqual(DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0), result);
    }

    @isTest
    static void parseGoogleDateTime_malformed_returnsNull() {
        DateTime result = GoogleCalendarService.parseGoogleDateTime('not-a-date');
        Assert.isNull(result);
    }


    private static GoogleCalendarModels.EventRequest makeRequest() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        return new GoogleCalendarModels.EventRequest('Summary', 'Desc', start, endDt, 'UTC');
    }
}
