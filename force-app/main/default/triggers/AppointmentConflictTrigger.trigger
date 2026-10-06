/**
 * Runs before Appointment__c is saved (insert or update).
 * Trigger.new is the list of records about to be saved.
 * validateAppointments adds an error on any overlapping booking.
 */
trigger AppointmentConflictTrigger on Appointment__c (before insert, before update) {
    AppointmentConflictService.validateAppointments(Trigger.new);
}
