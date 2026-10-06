Doctor__c d = [SELECT Id FROM Doctor__c LIMIT 1];
List<Patient__c> patients = [SELECT Id FROM Patient__c LIMIT 2];

Datetime slot = Datetime.now().addDays(1);

Appointment__c first = new Appointment__c(
    Doctor__c = d.Id,
    Patient__c = patients[0].Id,
    Appointment_Date__c = slot,
    Status__c = 'Scheduled'
);
insert first;

AppointmentConflictService.ConflictResult r =
    AppointmentConflictService.checkConflicts(
        d.Id,
        patients[1].Id,
        slot.addMinutes(10),
        null
    );
System.debug(r.hasConflict + ' ' + r.message);