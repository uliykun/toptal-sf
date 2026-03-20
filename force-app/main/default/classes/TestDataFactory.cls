// Factory for creating test SObjects.
// createXxx(true) inserts the record and returns it with a real Id.
// createXxx(false) returns an in-memory record without any DML.
@IsTest
public class TestDataFactory {

    // record type IDs — lazy-loaded once per test transaction
    private static Id doctorRecordTypeId;
    private static Id patientRecordTypeId;

    public static Id getDoctorRecordTypeId() {
        if (doctorRecordTypeId == null) {
            doctorRecordTypeId = [
                SELECT Id FROM RecordType
                WHERE SObjectType = 'Contact'
                AND DeveloperName = 'Doctor'
                LIMIT 1
            ].Id;
        }
        return doctorRecordTypeId;
    }

    public static Id getPatientRecordTypeId() {
        if (patientRecordTypeId == null) {
            patientRecordTypeId = [
                SELECT Id FROM RecordType
                WHERE SObjectType = 'Contact'
                AND DeveloperName = 'Patient'
                LIMIT 1
            ].Id;
        }
        return patientRecordTypeId;
    }

    // Doctor Contact with Cardiology specialization and a Google Calendar ID
    public static Contact createDoctor(Boolean doInsert) {
        Contact doc = new Contact(
            FirstName = 'James',
            LastName = 'Carter',
            Email = 'james.carter@clinic.test',
            RecordTypeId = getDoctorRecordTypeId(),
            Specialization__c = 'Cardiology',
            Google_Calendar_Id__c = 'cal123@group.calendar.google.com'
        );
        if (doInsert) insert doc;
        return doc;
    }

    // Patient Contact
    public static Contact createPatient(Boolean doInsert) {
        Contact pat = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe@patient.test',
            RecordTypeId = getPatientRecordTypeId()
        );
        if (doInsert) insert pat;
        return pat;
    }
}
