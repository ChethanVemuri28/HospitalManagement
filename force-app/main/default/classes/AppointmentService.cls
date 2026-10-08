public with sharing class AppointmentService {

    public class AppointmentException extends Exception {}


    public static Id createAppointment(
        Id doctorId,
        Id patientId,
        Datetime appointmentDate,
        String notes
    ) {

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
}