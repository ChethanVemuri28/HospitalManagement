/**
 * Unit tests for appointment overlap logic.
 * @IsTest means Salesforce treats this as a test class (not production logic).
 * Data created here is not saved to your real org after the test finishes.
 */
@IsTest
private class AppointmentConflictServiceTest {
    /**
     * Runs once before each test method in this class.
     * Creates one doctor, two patients, and a 10:00 appointment for Patient One.
     */
    @TestSetup
    static void setup() {
        Doctor__c doc = new Doctor__c(Name = 'Dr Test');
        insert doc;
        Patient__c pat1 = new Patient__c(Name = 'Patient One');
        Patient__c pat2 = new Patient__c(Name = 'Patient Two');
        insert new List<Patient__c>{ pat1, pat2 };

        insert new Appointment__c(
            Doctor__c = doc.Id,
            Patient__c = pat1.Id,
            Appointment_Date__c = Datetime.newInstance(2026, 10, 6, 10, 0, 0),
            Status__c = 'Scheduled'
        );
    }

    // Same doctor at 10:15 overlaps the 10:00–10:30 slot, even for a different patient.
    @IsTest
    static void overlappingDoctorIsConflict() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        Patient__c other = [SELECT Id FROM Patient__c WHERE Name = 'Patient Two'];

        Test.startTest();
        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doc.Id,
                other.Id,
                Datetime.newInstance(2026, 10, 6, 10, 15, 0),
                null
            );
        Test.stopTest();

        System.assertEquals(true, result.hasConflict);
    }

    // 10:30 starts exactly when the 10:00 slot ends, so it is allowed.
    @IsTest
    static void backToBackIsAllowed() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        Patient__c other = [SELECT Id FROM Patient__c WHERE Name = 'Patient Two'];

        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doc.Id,
                other.Id,
                Datetime.newInstance(2026, 10, 6, 10, 30, 0),
                null
            );

        System.assertEquals(false, result.hasConflict);
    }

    // Inserting a conflicting row through DML should be blocked by the trigger.
    @IsTest
    static void triggerBlocksInsert() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        Patient__c other = [SELECT Id FROM Patient__c WHERE Name = 'Patient Two'];
        Boolean blocked = false;
        try {
            insert new Appointment__c(
                Doctor__c = doc.Id,
                Patient__c = other.Id,
                Appointment_Date__c = Datetime.newInstance(2026, 10, 6, 10, 0, 0),
                Status__c = 'Scheduled'
            );
        } catch (DmlException e) {
            blocked = e.getMessage().contains('Conflict');
        }
        System.assertEquals(true, blocked);
    }
}
