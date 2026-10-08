@IsTest
private class AppointmentConflictServiceTest {

    private static Doctor__c createDoctor() {

        Doctor__c doctor = new Doctor__c(
            Name = 'Dr. Test Doctor'
        );

        insert doctor;

        return doctor;
    }


    private static Patient__c createPatient(
        String name
    ) {

        Patient__c patient = new Patient__c(
            Name = name
        );

        insert patient;

        return patient;
    }


    @IsTest
    static void testNoConflict() {

        Doctor__c doctor = createDoctor();
        Patient__c patient = createPatient('John Test');

        Datetime appointmentTime =
            Datetime.newInstance(
                2026,
                10,
                10,
                10,
                0,
                0
            );

        Test.startTest();

        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doctor.Id,
                patient.Id,
                appointmentTime,
                null
            );

        Test.stopTest();

        System.assertEquals(
            false,
            result.hasConflict
        );

        System.assertEquals(
            'Slot is available.',
            result.message
        );
    }


    @IsTest
    static void testDoctorConflict() {

        Doctor__c doctor = createDoctor();

        Patient__c patient1 =
            createPatient('Patient One');

        Patient__c patient2 =
            createPatient('Patient Two');

        Datetime existingTime =
            Datetime.newInstance(
                2026,
                10,
                10,
                10,
                0,
                0
            );

        insert new Appointment__c(
            Doctor__c = doctor.Id,
            Patient__c = patient1.Id,
            Appointment_Date__c = existingTime,
            Status__c = 'Scheduled'
        );

        Datetime conflictingTime =
            existingTime.addMinutes(15);

        Test.startTest();

        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doctor.Id,
                patient2.Id,
                conflictingTime,
                null
            );

        Test.stopTest();

        System.assertEquals(
            true,
            result.hasConflict
        );

        System.assert(
            result.message.contains('doctor')
        );
    }


    @IsTest
    static void testPatientConflict() {

        Doctor__c doctor1 = createDoctor();
        Doctor__c doctor2 = createDoctor();

        Patient__c patient =
            createPatient('Patient One');

        Datetime existingTime =
            Datetime.newInstance(
                2026,
                10,
                10,
                10,
                0,
                0
            );

        insert new Appointment__c(
            Doctor__c = doctor1.Id,
            Patient__c = patient.Id,
            Appointment_Date__c = existingTime,
            Status__c = 'Scheduled'
        );

        Test.startTest();

        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doctor2.Id,
                patient.Id,
                existingTime.addMinutes(15),
                null
            );

        Test.stopTest();

        System.assertEquals(
            true,
            result.hasConflict
        );

        System.assert(
            result.message.contains('patient')
        );
    }


    @IsTest
    static void testBackToBackAppointmentAllowed() {

        Doctor__c doctor = createDoctor();

        Patient__c patient1 =
            createPatient('Patient One');

        Patient__c patient2 =
            createPatient('Patient Two');

        Datetime existingTime =
            Datetime.newInstance(
                2026,
                10,
                10,
                10,
                0,
                0
            );

        insert new Appointment__c(
            Doctor__c = doctor.Id,
            Patient__c = patient1.Id,
            Appointment_Date__c = existingTime,
            Status__c = 'Scheduled'
        );

        Test.startTest();

        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doctor.Id,
                patient2.Id,
                existingTime.addMinutes(30),
                null
            );

        Test.stopTest();

        System.assertEquals(
            false,
            result.hasConflict
        );
    }


    @IsTest
    static void testCancelledAppointmentIgnored() {

        Doctor__c doctor = createDoctor();

        Patient__c patient1 =
            createPatient('Patient One');

        Patient__c patient2 =
            createPatient('Patient Two');

        Datetime appointmentTime =
            Datetime.newInstance(
                2026,
                10,
                10,
                10,
                0,
                0
            );

        insert new Appointment__c(
            Doctor__c = doctor.Id,
            Patient__c = patient1.Id,
            Appointment_Date__c = appointmentTime,
            Status__c = 'Cancelled'
        );

        Test.startTest();

        AppointmentConflictService.ConflictResult result =
            AppointmentConflictService.checkConflicts(
                doctor.Id,
                patient2.Id,
                appointmentTime,
                null
            );

        Test.stopTest();

        System.assertEquals(
            false,
            result.hasConflict
        );
    }
}