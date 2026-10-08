@IsTest
private class AppointmentControllerTest {

    private static Doctor__c createDoctor() {

        Doctor__c doctor = new Doctor__c(
            Name = 'Dr. Controller Test'
        );

        insert doctor;

        return doctor;
    }


    private static Patient__c createPatient() {

        Patient__c patient = new Patient__c(
            Name = 'Controller Test Patient'
        );

        insert patient;

        return patient;
    }


    @IsTest
    static void testBookAppointment() {

        Doctor__c doctor = createDoctor();
        Patient__c patient = createPatient();

        Datetime appointmentTime =
            Datetime.newInstance(
                2026,
                10,
                20,
                10,
                0,
                0
            );

        Test.startTest();

        Id appointmentId =
            AppointmentController.bookAppointment(
                doctor.Id,
                patient.Id,
                appointmentTime,
                'Controller booking'
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            appointmentId
        );

        Appointment__c appointment = [
            SELECT Id, Status__c
            FROM Appointment__c
            WHERE Id = :appointmentId
        ];

        System.assertEquals(
            'Scheduled',
            appointment.Status__c
        );
    }


    @IsTest
    static void testCheckAvailability() {

        Doctor__c doctor = createDoctor();
        Patient__c patient = createPatient();

        Datetime appointmentTime =
            Datetime.newInstance(
                2026,
                10,
                20,
                11,
                0,
                0
            );

        Test.startTest();

        AppointmentConflictService.ConflictResult result =
            AppointmentController.checkAvailability(
                doctor.Id,
                patient.Id,
                appointmentTime
            );

        Test.stopTest();

        System.assertEquals(
            false,
            result.hasConflict
        );
    }


    @IsTest
    static void testGetAppointments() {

        Doctor__c doctor = createDoctor();
        Patient__c patient = createPatient();

        insert new Appointment__c(
            Doctor__c = doctor.Id,
            Patient__c = patient.Id,
            Appointment_Date__c =
                Datetime.newInstance(
                    2026,
                    10,
                    20,
                    12,
                    0,
                    0
                ),
            Status__c = 'Scheduled'
        );

        Test.startTest();

        List<Appointment__c> appointments =
            AppointmentController.getAppointments();

        Test.stopTest();

        System.assert(
            appointments.size() > 0
        );
    }


    @IsTest
    static void testCancelAppointment() {

        Doctor__c doctor = createDoctor();
        Patient__c patient = createPatient();

        Appointment__c appointment =
            new Appointment__c(
                Doctor__c = doctor.Id,
                Patient__c = patient.Id,
                Appointment_Date__c =
                    Datetime.newInstance(
                        2026,
                        10,
                        20,
                        13,
                        0,
                        0
                    ),
                Status__c = 'Scheduled'
            );

        insert appointment;

        Test.startTest();

        AppointmentController.cancelAppointment(
            appointment.Id
        );

        Test.stopTest();

        Appointment__c result = [
            SELECT Status__c
            FROM Appointment__c
            WHERE Id = :appointment.Id
        ];

        System.assertEquals(
            'Cancelled',
            result.Status__c
        );
    }
}