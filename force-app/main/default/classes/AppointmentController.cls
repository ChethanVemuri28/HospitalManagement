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

    AppointmentConflictService.ConflictResult result =
        new AppointmentConflictService.ConflictResult();

    // First: check whether the doctor is working.
    DoctorAvailabilityService.AvailabilityResult availability =
        DoctorAvailabilityService.checkAvailability(
            doctorId,
            appointmentDate
        );

    if (!availability.isAvailable) {
        result.hasConflict = true;
        result.message = availability.message;
        result.conflictingAppointments =
            new List<Appointment__c>();

        return result;
    }

    // Second: check existing appointment conflicts.
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

    @AuraEnabled
    public static void completeAppointment(
        Id appointmentId
    ) {
        AppointmentService.completeAppointment(
            appointmentId
        );  
    }

    @AuraEnabled
    public static void rescheduleAppointment(
        Id appointmentId,
        Datetime newAppointmentDate
    ) {
        try {
            AppointmentService.rescheduleAppointment(
                appointmentId,
                newAppointmentDate
            );
        } catch (AppointmentService.AppointmentException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}