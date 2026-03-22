@isTest
private class UtilsTest {

    @isTest
    static void throwHandled_throwsWithCorrectMessage() {
        AuraHandledException caught;
        try {
            Utils.throwHandled('Something went wrong');
        } catch (AuraHandledException ex) {
            caught = ex;
        }
        Assert.isNotNull(caught);
        Assert.areEqual('Something went wrong', caught.getMessage());
    }

    @isTest
    static void validateNotBlank_throwsOnBlankString() {
        AuraHandledException caught;
        try {
            Utils.validateNotBlank('', 'Patient Name');
        } catch (AuraHandledException ex) {
            caught = ex;
        }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Patient Name'));
        Assert.isTrue(caught.getMessage().contains('is required'));
    }

    @isTest
    static void validateNotBlank_throwsOnNull() {
        AuraHandledException caught;
        try {
            Utils.validateNotBlank(null, 'Email');
        } catch (AuraHandledException ex) {
            caught = ex;
        }
        Assert.isNotNull(caught);
    }

    @isTest
    static void validateNotBlank_doesNotThrowOnValidValue() {
        Utils.validateNotBlank('john@example.com', 'Email');
        Assert.isTrue(true);
    }

    @isTest
    static void validateAllNotBlank_collectsAllErrors() {
        AuraHandledException caught;
        try {
            Utils.validateAllNotBlank(new Map<String, String>{
                'First Name' => '',
                'Last Name' => null,
                'Email' => 'valid@example.com'
            });
        } catch (AuraHandledException ex) {
            caught = ex;
        }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('First Name'));
        Assert.isTrue(caught.getMessage().contains('Last Name'));
        Assert.isFalse(caught.getMessage().contains('Email'));
    }

    @isTest
    static void validateAllNotBlank_doesNotThrowWhenAllPopulated() {
        Utils.validateAllNotBlank(new Map<String, String>{
            'First' => 'John',
            'Last' => 'Doe'
        });
        Assert.isTrue(true);
    }

    @isTest
    static void parseIsoDateTime_parsesWithoutZ() {
        DateTime result = Utils.parseIsoDateTime('2026-03-21T10:30:00');
        Assert.areEqual(2026, result.yearGmt());
        Assert.areEqual(3, result.monthGmt());
        Assert.areEqual(21, result.dayGmt());
        Assert.areEqual(10, result.hourGmt());
        Assert.areEqual(30, result.minuteGmt());
    }

    @isTest
    static void parseIsoDateTime_parsesWithTrailingZ() {
        DateTime result = Utils.parseIsoDateTime('2026-03-21T10:00:00Z');
        Assert.areEqual(2026, result.yearGmt());
        Assert.areEqual(3, result.monthGmt());
        Assert.areEqual(21, result.dayGmt());
    }

    @isTest
    static void parseIsoDateTime_throwsOnBlank() {
        AuraHandledException caught;
        try {
            Utils.parseIsoDateTime(' ');
        } catch (AuraHandledException ex) {
            caught = ex;
        }
        Assert.isNotNull(caught);
    }

    @isTest
    static void parseIsoDateTime_throwsOnInvalidFormat() {
        AuraHandledException caught;
        try {
            Utils.parseIsoDateTime('not-a-date');
        } catch (AuraHandledException ex) {
            caught = ex;
        }
        Assert.isNotNull(caught);
        Assert.isTrue(caught.getMessage().contains('Invalid datetime format'));
    }
}
