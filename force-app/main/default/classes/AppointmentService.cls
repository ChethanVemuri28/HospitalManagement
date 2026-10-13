public with sharing class AppointmentService {

    public class AppointmentException extends Exception {}


    public static Id createAppointment(
        Id doctorId,
        Id patientId,
        Datetime appointmentDate,
        String notes
    ) {

        DoctorAvailabilityService.AvailabilityResult availability =
            DoctorAvailabilityService.checkAvailability(
                doctorId,
                appointmentDate
            );

        if (!availability.isAvailable) {
            throw new AppointmentException(availability.message);
        }

        AppointmentConflictService.ConflictResult check =
            AppointmentConflictService.checkConflicts(
                doctorId,
                patientId,
                appointmentDate,
                null
            );

        if (check.hasConflict) {

            throw new AppointmentException(
                check.message
            );
        }

        Appointment__c appointment =
            new Appointment__c(
                Doctor__c = doctorId,
                Patient__c = patientId,
                Appointment_Date__c = appointmentDate,
                Status__c = 'Scheduled',
                Notes__c = notes
            );

        insert appointment;

        return appointment.Id;
    }


    public static void cancelAppointment(
        Id appointmentId
    ) {

        Appointment__c appointment = [
            SELECT Id, Status__c
            FROM Appointment__c
            WHERE Id = :appointmentId
            LIMIT 1
        ];

        appointment.Status__c = 'Cancelled';

        update appointment;
    }

    public static void completeAppointment(
        Id appointmentId
    ) {

        Appointment__c appointment = [
            SELECT Id, Status__c
            FROM Appointment__c
            WHERE Id = :appointmentId
            LIMIT 1
        ];

        appointment.Status__c = 'Completed';

        update appointment;
    }

    public static void rescheduleAppointment(
        Id appointmentId,
        Datetime newAppointmentDate
    ) {

        if(appointmentId == null || newAppointmentDate == null) {
            throw new AppointmentException('Appointment ID and new appointment date must be provided.');
        }

        Appointment__c appointment = [
            SELECT Id, Doctor__c, Patient__c, Appointment_Date__c, Status__c
            FROM Appointment__c
            WHERE Id = :appointmentId
            LIMIT 1
        ];

        if (appointment.Status__c != 'Scheduled') {
            throw new AppointmentException(
                'Only scheduled appointments can be rescheduled.'
            );
        }

        DoctorAvailabilityService.AvailabilityResult availability =
            DoctorAvailabilityService.checkAvailability(
                appointment.Doctor__c,
                newAppointmentDate
            );

        if (!availability.isAvailable) {
            throw new AppointmentException(availability.message);
        }

        // Check Doctor ad patient conflicts
        // Exclude this appointment so it does not conflict with itself

        AppointmentConflictService.ConflictResult check =
            AppointmentConflictService.checkConflicts(
                appointment.Doctor__c,
                appointment.Patient__c,
                newAppointmentDate,
                appointmentId
            );

        if (check.hasConflict) {
            throw new AppointmentException(check.message);
        }

        // Update the existing record, not create a new one

        appointment.Appointment_Date__c = newAppointmentDate;

        update appointment;
    }
}