@isTest
private class GoogleCalendarControllerHelperTest {

    @isTest
    static void validateCreateEventInputs_allValid_noException() {
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateCreateEventInputs(
                new GoogleCalendarModels.CreateEventInput(
                    'primary', 'John Doe', 'Smith', 'Cardiology',
                    '2026-03-21T10:00:00', '2026-03-21T11:00:00', 'UTC', null
                )
            );
        } catch (Exception ex) { caught = ex; }

        Assert.isNull(caught);
    }

    @isTest
    static void validateCreateEventInputs_blankCalendarId_throws() {
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateCreateEventInputs(
                new GoogleCalendarModels.CreateEventInput(
                    '', 'John Doe', 'Smith', 'Cardiology',
                    '2026-03-21T10:00:00', '2026-03-21T11:00:00', 'UTC', null
                )
            );
        } catch (Exception ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }

    @isTest
    static void validateCreateEventInputs_multipleBlankFields_includesAllErrors() {
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateCreateEventInputs(
                new GoogleCalendarModels.CreateEventInput(
                    '', 'John Doe', '', 'Cardiology',
                    '2026-03-21T10:00:00', '2026-03-21T11:00:00', 'UTC', null
                )
            );
        } catch (Exception ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
        Assert.isTrue(caught.getMessage().contains('Physician name'));
    }

    @isTest
    static void validateCreateEventInputs_allBlank_throws() {
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateCreateEventInputs(
                new GoogleCalendarModels.CreateEventInput(
                    '', '', '', '', '', '', '', null
                )
            );
        } catch (Exception ex) { caught = ex; }

        Assert.isNotNull(caught);
    }


    @isTest
    static void validateTimeWindow_endBeforeStart_throws() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateTimeWindow(start, endDt);
        } catch (Exception ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('after start time'));
    }

    @isTest
    static void validateTimeWindow_endEqualsStart_throws() {
        DateTime dt = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateTimeWindow(dt, dt);
        } catch (Exception ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('after start time'));
    }

    @isTest
    static void validateTimeWindow_validWindow_noException() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        Exception caught;
        try {
            GoogleCalendarControllerHelper.validateTimeWindow(start, endDt);
        } catch (Exception ex) { caught = ex; }

        Assert.isNull(caught);
    }


    @isTest
    static void orchestrateCreateEvent_success_returnsHtmlLink() {
        String eventJson =
            '{"id":"evt1","status":"confirmed","htmlLink":"https://cal.google.com/event"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, eventJson));
        Test.startTest();
        String link = GoogleCalendarControllerHelper.orchestrateCreateEvent(
            new GoogleCalendarModels.CreateEventInput(
                'primary', 'John Doe', 'Smith', 'Cardiology',
                null, null, 'UTC', 'john@example.com'
            ),
            DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0),
            DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0)
        );
        Test.stopTest();

        Assert.areEqual('https://cal.google.com/event', link);
    }


    @isTest
    static void orchestrateGetSlots_success_returnsSlots() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"items":[]}'));
        Test.startTest();
        List<GoogleCalendarModels.TimeSlot> slots =
            GoogleCalendarControllerHelper.orchestrateGetSlots('primary', '2026-03-21', 'UTC');
        Test.stopTest();

        Assert.isFalse(slots.isEmpty());
    }

    @isTest
    static void orchestrateGetSlots_blankCalendarId_throws() {
        Exception caught;
        try {
            GoogleCalendarControllerHelper.orchestrateGetSlots('', '2026-03-21', 'UTC');
        } catch (Exception ex) { caught = ex; }

        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Calendar ID'));
    }
}
