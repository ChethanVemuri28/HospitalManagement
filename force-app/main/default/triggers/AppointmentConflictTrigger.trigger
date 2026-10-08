trigger AppointmentConflictTrigger
    on Appointment__c (before insert, before update) {

    if (Trigger.isBefore &&
        (Trigger.isInsert || Trigger.isUpdate)) {

        AppointmentConflictService.validateAppointments(
            Trigger.new
        );
    }
}