@isTest
private class GoogleCalendarControllerTest {

    private static final String CAL_ID    = 'primary';
    private static final String START_ISO = '2026-03-21T10:00:00';
    private static final String END_ISO   = '2026-03-21T11:00:00';
    private static final String EVENT_JSON =
        '{"id":"evt1","status":"confirmed","htmlLink":"https://cal.google.com/event"}';

    // ── createCalendarEvent ───────────────────────────────────────────────────

    @isTest
    static void createCalendarEvent_success_returnsHtmlLink() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, EVENT_JSON));
        Test.startTest();
        String result = GoogleCalendarController.createCalendarEvent(
            CAL_ID, 'John Doe', 'Smith', 'Cardiology',
            START_ISO, END_ISO, 'UTC', 'john@example.com'
        );
        Test.stopTest();
        Assert.areEqual('https://cal.google.com/event', result);
    }

    @isTest
    static void createCalendarEvent_blankPatientName_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.createCalendarEvent(
                CAL_ID, '', 'Smith', 'Cardiology',
                START_ISO, END_ISO, 'UTC', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Patient name'));
    }

    @isTest
    static void createCalendarEvent_allFieldsBlank_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.createCalendarEvent(
                '', '', '', '', '', '', '', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
    }

    @isTest
    static void createCalendarEvent_invalidStartDate_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.createCalendarEvent(
                CAL_ID, 'John', 'Smith', 'Cardiology',
                'not-a-date', END_ISO, 'UTC', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Invalid datetime'));
    }

    @isTest
    static void createCalendarEvent_invalidEndDate_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.createCalendarEvent(
                CAL_ID, 'John', 'Smith', 'Cardiology',
                START_ISO, 'not-a-date', 'UTC', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Invalid datetime'));
    }

    @isTest
    static void createCalendarEvent_endBeforeStart_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.createCalendarEvent(
                CAL_ID, 'John', 'Smith', 'Cardiology',
                END_ISO, START_ISO, 'UTC', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('after start time'));
    }

    @isTest
    static void createCalendarEvent_endEqualsStart_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.createCalendarEvent(
                CAL_ID, 'John', 'Smith', 'Cardiology',
                START_ISO, START_ISO, 'UTC', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('after start time'));
    }

    @isTest
    static void createCalendarEvent_apiError_throwsAura() {
        Test.setMock(HttpCalloutMock.class,
            new MockHttpCallout(403, '{"error":{"code":403,"message":"Forbidden"}}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarController.createCalendarEvent(
                CAL_ID, 'John', 'Smith', 'Cardiology',
                START_ISO, END_ISO, 'UTC', null
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Forbidden'));
    }

    // ── getCalendarEvents ─────────────────────────────────────────────────────

    @isTest
    static void getCalendarEvents_success_returnsJson() {
        String eventsJson = '{"items":[{"id":"evt1"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, eventsJson));
        Test.startTest();
        String result = GoogleCalendarController.getCalendarEvents(
            CAL_ID, '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z'
        );
        Test.stopTest();
        Assert.areEqual(eventsJson, result);
    }

    @isTest
    static void getCalendarEvents_blankCalendarId_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.getCalendarEvents(
                '', '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z'
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void getCalendarEvents_blankTimeMin_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.getCalendarEvents(CAL_ID, '', '2026-03-22T00:00:00Z');
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('timeMin'));
    }

    @isTest
    static void getCalendarEvents_apiError_throwsAura() {
        Test.setMock(HttpCalloutMock.class,
            new MockHttpCallout(500, '{"error":{"code":500,"message":"Server Error"}}'));
        Exception caught;
        Test.startTest();
        try {
            GoogleCalendarController.getCalendarEvents(
                CAL_ID, '2026-03-21T00:00:00Z', '2026-03-22T00:00:00Z'
            );
        } catch (AuraHandledException ex) { caught = ex; }
        Test.stopTest();
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Server Error'));
    }

    // ── getAvailableSlots ─────────────────────────────────────────────────────

    @isTest
    static void getAvailableSlots_success_returnsSlots() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"items":[]}'));
        Test.startTest();
        List<GoogleCalendarModels.TimeSlot> slots =
            GoogleCalendarController.getAvailableSlots(CAL_ID, '2026-03-21', 'UTC');
        Test.stopTest();
        Assert.isFalse(slots.isEmpty());
    }

    @isTest
    static void getAvailableSlots_blankCalendarId_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.getAvailableSlots('', '2026-03-21', 'UTC');
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void getAvailableSlots_blankDate_throwsAura() {
        Exception caught;
        try {
            GoogleCalendarController.getAvailableSlots(CAL_ID, '', 'UTC');
        } catch (AuraHandledException ex) { caught = ex; }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Date'));
    }
}
