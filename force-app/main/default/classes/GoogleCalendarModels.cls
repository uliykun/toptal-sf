public class GoogleCalendarModels {

    public class EventDateTime {
        public String dateTimeStr;
        public String timeZone;
        public String dateStr;

        public EventDateTime() {}

        public EventDateTime(DateTime dt, String tz) {
            this.dateTimeStr = dt.format('yyyy-MM-dd\'T\'HH:mm:ss', tz);
            this.timeZone    = tz;
        }
    }

    public class Attendee {
        public String email;

        public Attendee() {}

        public Attendee(String emailAddress) {
            this.email = emailAddress;
        }
    }

    public class ApiError {
        public Integer              code;
        public String               message;
        public List<ApiErrorDetail> errors;
    }

    public class ApiErrorDetail {
        public String message;
        public String domain;
        public String reason;
    }

    public class EventRequest {
        public String         summary;
        public String         description;
        public String         location;
        public EventDateTime  start;
        public EventDateTime  endTime;
        public List<Attendee> attendees;

        public EventRequest(
                String   summary,
                String   description,
                DateTime startDt,
                DateTime endDt,
                String   timeZone) {
            this.summary     = summary;
            this.description = description;
            this.start       = new EventDateTime(startDt, timeZone);
            this.endTime     = new EventDateTime(endDt, timeZone);
            this.attendees   = new List<Attendee>();
        }

        public EventRequest addAttendee(String emailAddress) {
            if (String.isNotBlank(emailAddress)) {
                this.attendees.add(new Attendee(emailAddress));
            }
            return this;
        }

        public String toJsonBody() {
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeStartObject();
            gen.writeStringField('summary', summary);
            if (description != null) gen.writeStringField('description', description);
            if (location    != null) gen.writeStringField('location',    location);
            gen.writeFieldName('start');
            writeEventDateTime(gen, start);
            gen.writeFieldName('end');
            writeEventDateTime(gen, endTime);
            if (!attendees.isEmpty()) {
                gen.writeFieldName('attendees');
                gen.writeStartArray();
                for (Attendee a : attendees) {
                    gen.writeStartObject();
                    gen.writeStringField('email', a.email);
                    gen.writeEndObject();
                }
                gen.writeEndArray();
            }
            gen.writeEndObject();
            return gen.getAsString();
        }

        private void writeEventDateTime(JSONGenerator gen, EventDateTime edt) {
            gen.writeStartObject();
            if (edt.dateTimeStr != null) gen.writeStringField('dateTime', edt.dateTimeStr);
            if (edt.dateStr     != null) gen.writeStringField('date',     edt.dateStr);
            if (edt.timeZone    != null) gen.writeStringField('timeZone', edt.timeZone);
            gen.writeEndObject();
        }
    }

    public class EventResponse {
        public String   id;
        public String   status;
        public String   htmlLink;
        public String   summary;
        public ApiError error;

        public Boolean isSuccess() {
            return this.error == null && String.isNotBlank(this.id);
        }

        public String getErrorMessage() {
            if (this.error == null) return null;
            if (String.isNotBlank(this.error.message)) return this.error.message;
            if (this.error.errors != null && !this.error.errors.isEmpty()) {
                return this.error.errors[0].message;
            }
            return 'Google Calendar API error (code ' + this.error.code + ')';
        }
    }

    public class TimeSlot {
        @AuraEnabled public String  startIso;
        @AuraEnabled public String  endIso;
        @AuraEnabled public String  label;
        @AuraEnabled public Boolean isAvailable;

        public TimeSlot(DateTime slotStartUtc, DateTime slotEndUtc, String timeZone, Boolean isAvailable) {
            this.startIso    = slotStartUtc.format('yyyy-MM-dd\'T\'HH:mm:ss', timeZone);
            this.endIso      = slotEndUtc.format('yyyy-MM-dd\'T\'HH:mm:ss', timeZone);
            this.label       = slotStartUtc.format('h:mm a', timeZone);
            this.isAvailable = isAvailable;
        }
    }

    public static EventResponse parseEventResponse(String jsonBody) {
        return (EventResponse) JSON.deserialize(jsonBody, EventResponse.class);
    }
}
