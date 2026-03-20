public class Utils {

    public static void throwHandled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }

    public static void validateNotBlank(String value, String fieldLabel) {
        if (String.isBlank(value)) {
            throwHandled(fieldLabel + ' is required.');
        }
    }

    public static void validateAllNotBlank(Map<String, String> fieldMap) {
        List<String> errors = new List<String>();
        for (String label : fieldMap.keySet()) {
            if (String.isBlank(fieldMap.get(label))) {
                errors.add(label + ' is required.');
            }
        }
        if (!errors.isEmpty()) {
            throwHandled(String.join(errors, ' '));
        }
    }

    public static DateTime parseIsoDateTime(String isoString) {
        validateNotBlank(isoString, 'Datetime string');
        try {
            String normalised = isoString.removeEnd('Z').replace('T', ' ');
            return DateTime.valueOf(normalised);
        } catch (Exception ex) {
            throwHandled(
                'Invalid datetime format: "' + isoString + '". '
                + 'Expected ISO 8601 (e.g. 2026-03-21T10:00:00).'
            );
            return null;
        }
    }
}
