public with sharing class AppointmentController {

    @AuraEnabled
    public static Id bookAppointment(
        Id doctorId,
        Id patientId,
        Datetime appointmentDate,
        String notes
    ) {

        try {

            return AppointmentService.createAppointment(
                doctorId,
                patientId,
                appointmentDate,
                notes
            );

        } catch (AppointmentService.AppointmentException e) {

            throw new AuraHandledException(
                e.getMessage()
            );
        }
    }


    @AuraEnabled(cacheable=true)
    public static AppointmentConflictService.ConflictResult
        checkAvailability(
            Id doctorId,
            Id patientId,
            Datetime appointmentDate
        ) {

        return AppointmentConflictService.checkConflicts(
            doctorId,
            patientId,
            appointmentDate,
            null
        );
    }


    @AuraEnabled(cacheable=true)
    public static List<Appointment__c>
        getAppointments() {

        return [
            SELECT
                Id,
                Name,
                Appointment_Date__c,
                Status__c,
                Notes__c,
                Doctor__c,
                Doctor__r.Name,
                Patient__c,
                Patient__r.Name
            FROM Appointment__c
            ORDER BY Appointment_Date__c ASC
        ];
    }


    @AuraEnabled
    public static void cancelAppointment(
        Id appointmentId
    ) {

        AppointmentService.cancelAppointment(
            appointmentId
        );
    }
}