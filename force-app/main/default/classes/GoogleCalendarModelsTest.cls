@isTest
private class GoogleCalendarModelsTest {

    @isTest
    static void eventDateTime_noArgConstructor_fieldsAreNull() {
        GoogleCalendarModels.EventDateTime edt = new GoogleCalendarModels.EventDateTime();

        Assert.isNull(edt.dateTimeStr);
        Assert.isNull(edt.timeZone);
    }

    @isTest
    static void eventDateTime_dtConstructor_formatsInRequestedTimezone() {
        DateTime dt = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        GoogleCalendarModels.EventDateTime edt = new GoogleCalendarModels.EventDateTime(dt, 'UTC');

        Assert.areEqual('2026-03-21T10:00:00', edt.dateTimeStr);
        Assert.areEqual('UTC', edt.timeZone);
    }

    @isTest
    static void attendee_noArgConstructor_emailIsNull() {
        GoogleCalendarModels.Attendee a = new GoogleCalendarModels.Attendee();

        Assert.isNull(a.email);
    }

    @isTest
    static void attendee_emailConstructor_setsEmail() {
        GoogleCalendarModels.Attendee a = new GoogleCalendarModels.Attendee('doc@example.com');

        Assert.areEqual('doc@example.com', a.email);
    }

    @isTest
    static void eventRequest_constructor_setsAllFields() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = new GoogleCalendarModels.EventRequest(
            'My Summary', 'My Description', start, endDt, 'UTC'
        );

        Assert.areEqual('My Summary', req.summary);
        Assert.areEqual('My Description', req.description);
        Assert.isNotNull(req.start);
        Assert.isNotNull(req.endTime);
        Assert.areEqual(0, req.attendees.size());
    }

    @isTest
    static void eventRequest_addAttendee_appendsEmail() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = new GoogleCalendarModels.EventRequest(
            'S', 'D', start, endDt, 'UTC'
        );
        req.addAttendee('patient@example.com');

        Assert.areEqual(1, req.attendees.size());
        Assert.areEqual('patient@example.com', req.attendees[0].email);
    }

    @isTest
    static void eventRequest_addAttendee_ignoresBlankAndNull() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = new GoogleCalendarModels.EventRequest(
            'S', 'D', start, endDt, 'UTC'
        );
        req.addAttendee('');
        req.addAttendee(null);

        Assert.areEqual(0, req.attendees.size());
    }

    @isTest
    static void eventRequest_addAttendee_isFluent() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = new GoogleCalendarModels.EventRequest(
            'S', 'D', start, endDt, 'UTC'
        );
        GoogleCalendarModels.EventRequest returned = req.addAttendee('a@b.com');

        Assert.areEqual(req, returned);
    }

    @isTest
    static void eventRequest_toJsonBody_containsExpectedFields() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = new GoogleCalendarModels.EventRequest(
            'Cardiology Appointment', 'Patient: John', start, endDt, 'UTC'
        );
        String json = req.toJsonBody();

        Assert.isTrue(json.contains('Cardiology Appointment'));
        Assert.isTrue(json.contains('2026-03-21T10:00:00'));
        Assert.isTrue(json.contains('UTC'));
    }

    @isTest
    static void eventRequest_toJsonBody_suppressesNullLocation() {
        DateTime start = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime endDt = DateTime.newInstanceGmt(2026, 3, 21, 11, 0, 0);
        GoogleCalendarModels.EventRequest req = new GoogleCalendarModels.EventRequest(
            'S', 'D', start, endDt, 'UTC'
        );

        Assert.isFalse(req.toJsonBody().contains('"location"'));
    }

    @isTest
    static void eventResponse_isSuccess_trueWhenIdPresent() {
        GoogleCalendarModels.EventResponse r =
            GoogleCalendarModels.parseEventResponse('{"id":"evt1","status":"confirmed"}');

        Assert.isTrue(r.isSuccess());
    }

    @isTest
    static void eventResponse_isSuccess_falseWhenIdBlank() {
        GoogleCalendarModels.EventResponse r = GoogleCalendarModels.parseEventResponse('{"status":"confirmed"}');

        Assert.isFalse(r.isSuccess());
    }

    @isTest
    static void eventResponse_isSuccess_falseWhenErrorPresent() {
        GoogleCalendarModels.EventResponse r =
            GoogleCalendarModels.parseEventResponse('{"error":{"code":401,"message":"Unauthorized"}}');

        Assert.isFalse(r.isSuccess());
    }

    @isTest
    static void eventResponse_getErrorMessage_returnsNullOnSuccess() {
        GoogleCalendarModels.EventResponse r =
            GoogleCalendarModels.parseEventResponse('{"id":"evt1"}');

        Assert.isNull(r.getErrorMessage());
    }

    @isTest
    static void eventResponse_getErrorMessage_returnsTopLevelMessage() {
        GoogleCalendarModels.EventResponse r =
            GoogleCalendarModels.parseEventResponse('{"error":{"code":403,"message":"Forbidden"}}');

        Assert.areEqual('Forbidden', r.getErrorMessage());
    }

    @isTest
    static void eventResponse_getErrorMessage_fallsBackToErrorDetails() {
        String json = '{"error":{"code":403,"errors":[{"message":"Insufficient permissions"}]}}';
        GoogleCalendarModels.EventResponse r = GoogleCalendarModels.parseEventResponse(json);

        Assert.areEqual('Insufficient permissions', r.getErrorMessage());
    }

    @isTest
    static void eventResponse_getErrorMessage_fallsBackToErrorCode() {
        GoogleCalendarModels.EventResponse r = GoogleCalendarModels.parseEventResponse('{"error":{"code":418}}');

        Assert.isTrue(r.getErrorMessage().contains('418'));
    }

    @isTest
    static void parseEventResponse_throwsOnMalformedJson() {
        Exception caught;
        try {
            GoogleCalendarModels.parseEventResponse('{bad json');
        } catch (Exception ex) {
            caught = ex;
        }

        Assert.isNotNull(caught);
    }

    @isTest
    static void timeSlot_constructor_setsAllFields() {
        DateTime slotStart = DateTime.newInstanceGmt(2026, 3, 21, 9, 0, 0);
        DateTime slotEnd = DateTime.newInstanceGmt(2026, 3, 21, 9, 30, 0);
        GoogleCalendarModels.TimeSlot slot = new GoogleCalendarModels.TimeSlot(slotStart, slotEnd, 'UTC', true);

        Assert.areEqual('2026-03-21T09:00:00', slot.startIso);
        Assert.areEqual('2026-03-21T09:30:00', slot.endIso);
        Assert.isTrue(slot.label.contains('9'));
        Assert.isTrue(slot.isAvailable);
    }

    @isTest
    static void timeSlot_isAvailableFalse_whenBooked() {
        DateTime slotStart = DateTime.newInstanceGmt(2026, 3, 21, 10, 0, 0);
        DateTime slotEnd = DateTime.newInstanceGmt(2026, 3, 21, 10, 30, 0);
        GoogleCalendarModels.TimeSlot slot = new GoogleCalendarModels.TimeSlot(slotStart, slotEnd, 'UTC', false);

        Assert.isFalse(slot.isAvailable);
    }


    @isTest
    static void createEventInput_constructor_setsAllFields() {
        GoogleCalendarModels.CreateEventInput input = new GoogleCalendarModels.CreateEventInput(
            'primary', 'John Doe', 'Dr. Smith', 'Cardiology',
            '2026-03-21T10:00:00', '2026-03-21T11:00:00', 'UTC', 'john@example.com'
        );

        Assert.areEqual('primary', input.calendarId);
        Assert.areEqual('John Doe', input.patientName);
        Assert.areEqual('Dr. Smith', input.physicianName);
        Assert.areEqual('Cardiology', input.specialization);
        Assert.areEqual('2026-03-21T10:00:00', input.startIso);
        Assert.areEqual('2026-03-21T11:00:00', input.endIso);
        Assert.areEqual('UTC', input.timeZone);
        Assert.areEqual('john@example.com', input.patientEmail);
    }

    @isTest
    static void createEventInput_nullPatientEmail_isAllowed() {
        GoogleCalendarModels.CreateEventInput input = new GoogleCalendarModels.CreateEventInput(
            'primary', 'John Doe', 'Dr. Smith', 'Cardiology',
            '2026-03-21T10:00:00', '2026-03-21T11:00:00', 'UTC', null
        );

        Assert.isNull(input.patientEmail);
    }
}
