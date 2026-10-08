@IsTest
private class AppointmentServiceTest {

    private static Doctor__c createDoctor() {

        Doctor__c doctor = new Doctor__c(
            Name = 'Dr. Service Test'
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
    static void testCreateAppointment() {

        Doctor__c doctor = createDoctor();
        Patient__c patient =
            createPatient('Booking Test Patient');

        Datetime appointmentTime =
            Datetime.newInstance(
                2026,
                10,
                15,
                10,
                0,
                0
            );

        Test.startTest();

        Id appointmentId =
            AppointmentService.createAppointment(
                doctor.Id,
                patient.Id,
                appointmentTime,
                'General consultation'
            );

        Test.stopTest();

        Appointment__c result = [
            SELECT
                Id,
                Doctor__c,
                Patient__c,
                Appointment_Date__c,
                Status__c,
                Notes__c
            FROM Appointment__c
            WHERE Id = :appointmentId
        ];

        System.assertEquals(
            doctor.Id,
            result.Doctor__c
        );

        System.assertEquals(
            patient.Id,
            result.Patient__c
        );

        System.assertEquals(
            'Scheduled',
            result.Status__c
        );

        System.assertEquals(
            'General consultation',
            result.Notes__c
        );
    }


    @IsTest
    static void testConflictPreventsBooking() {

        Doctor__c doctor = createDoctor();

        Patient__c patient1 =
            createPatient('Patient One');

        Patient__c patient2 =
            createPatient('Patient Two');

        Datetime appointmentTime =
            Datetime.newInstance(
                2026,
                10,
                15,
                10,
                0,
                0
            );

        insert new Appointment__c(
            Doctor__c = doctor.Id,
            Patient__c = patient1.Id,
            Appointment_Date__c = appointmentTime,
            Status__c = 'Scheduled'
        );

        Test.startTest();

        try {

            AppointmentService.createAppointment(
                doctor.Id,
                patient2.Id,
                appointmentTime.addMinutes(15),
                null
            );

            System.assert(
                false,
                'Expected AppointmentException'
            );

        } catch (
            AppointmentService.AppointmentException e
        ) {

            System.assert(
                e.getMessage().contains('doctor')
            );
        }

        Test.stopTest();
    }


    @IsTest
    static void testCancelAppointment() {

        Doctor__c doctor = createDoctor();

        Patient__c patient =
            createPatient('Cancel Test Patient');

        Appointment__c appointment =
            new Appointment__c(
                Doctor__c = doctor.Id,
                Patient__c = patient.Id,
                Appointment_Date__c =
                    Datetime.newInstance(
                        2026,
                        10,
                        15,
                        14,
                        0,
                        0
                    ),
                Status__c = 'Scheduled'
            );

        insert appointment;

        Test.startTest();

        AppointmentService.cancelAppointment(
            appointment.Id
        );

        Test.stopTest();

        Appointment__c result = [
            SELECT Id, Status__c
            FROM Appointment__c
            WHERE Id = :appointment.Id
        ];

        System.assertEquals(
            'Cancelled',
            result.Status__c
        );
    }
}