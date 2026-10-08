public with sharing class AppointmentConflictService {

    public static final Integer SLOT_MINUTES = 30;

    public class ConflictResult {
        @AuraEnabled public Boolean hasConflict;
        @AuraEnabled public String message;
        @AuraEnabled public List<Appointment__c> conflictingAppointments;
    }

    /*
     * Used by LWC to check whether a particular slot is available.
     */
    @AuraEnabled(cacheable=true)
    public static ConflictResult checkConflicts(
        Id doctorId,
        Id patientId,
        Datetime appointmentDate,
        Id excludeAppointmentId
    ) {

        ConflictResult result = new ConflictResult();
        result.hasConflict = false;
        result.conflictingAppointments =
            new List<Appointment__c>();

        if (doctorId == null ||
            patientId == null ||
            appointmentDate == null) {

            result.message =
                'Doctor, Patient, and Appointment Date are required.';

            return result;
        }

        Datetime windowStart =
            appointmentDate.addMinutes(-SLOT_MINUTES);

        Datetime windowEnd =
            appointmentDate.addMinutes(SLOT_MINUTES);

        List<Appointment__c> matches = [
            SELECT
                Id,
                Name,
                Doctor__c,
                Patient__c,
                Appointment_Date__c,
                Status__c,
                Notes__c
            FROM Appointment__c
            WHERE Status__c != 'Cancelled'
            AND Appointment_Date__c > :windowStart
            AND Appointment_Date__c < :windowEnd
            AND (
                Doctor__c = :doctorId
                OR Patient__c = :patientId
            )
            AND Id != :excludeAppointmentId
        ];

        if (!matches.isEmpty()) {

            result.hasConflict = true;
            result.conflictingAppointments = matches;

            result.message =
                buildMessage(matches, doctorId, patientId);

        } else {

            result.message = 'Slot is available.';
        }

        return result;
    }


    /*
     * Bulk-safe trigger validation.
     */
    public static void validateAppointments(
        List<Appointment__c> appointments
    ) {

        Set<Id> doctorIds = new Set<Id>();
        Set<Id> patientIds = new Set<Id>();

        Datetime earliestStart;
        Datetime latestStart;

        for (Appointment__c appt : appointments) {

            if (appt.Status__c == 'Cancelled') {
                continue;
            }

            if (appt.Doctor__c != null) {
                doctorIds.add(appt.Doctor__c);
            }

            if (appt.Patient__c != null) {
                patientIds.add(appt.Patient__c);
            }

            if (appt.Appointment_Date__c != null) {

                Datetime start =
                    appt.Appointment_Date__c
                        .addMinutes(-SLOT_MINUTES);

                Datetime appointmentEnd =
                    appt.Appointment_Date__c
                        .addMinutes(SLOT_MINUTES);

                if (earliestStart == null ||
                    start < earliestStart) {

                    earliestStart = start;
                }

                if (latestStart == null ||
                    appointmentEnd > latestStart) {

                    latestStart = appointmentEnd;
                }
            }
        }

        if (doctorIds.isEmpty() &&
            patientIds.isEmpty()) {
            return;
        }

        List<Appointment__c> existingAppointments = [
            SELECT
                Id,
                Name,
                Doctor__c,
                Patient__c,
                Appointment_Date__c,
                Status__c
            FROM Appointment__c
            WHERE Status__c != 'Cancelled'
            AND Appointment_Date__c >= :earliestStart
            AND Appointment_Date__c <= :latestStart
            AND (
                Doctor__c IN :doctorIds
                OR Patient__c IN :patientIds
            )
        ];

        for (Appointment__c newAppt : appointments) {

            if (newAppt.Status__c == 'Cancelled' ||
                newAppt.Appointment_Date__c == null) {
                continue;
            }

            Datetime newStart =
                newAppt.Appointment_Date__c;

            Datetime newEnd =
                newStart.addMinutes(SLOT_MINUTES);

            for (Appointment__c existing : existingAppointments) {

                if (existing.Id == newAppt.Id) {
                    continue;
                }

                if (existing.Appointment_Date__c == null) {
                    continue;
                }

                Datetime existingStart =
                    existing.Appointment_Date__c;

                Datetime existingEnd =
                    existingStart.addMinutes(SLOT_MINUTES);

                Boolean overlaps =
                    newStart < existingEnd &&
                    newEnd > existingStart;

                Boolean sameDoctor =
                    newAppt.Doctor__c != null &&
                    newAppt.Doctor__c == existing.Doctor__c;

                Boolean samePatient =
                    newAppt.Patient__c != null &&
                    newAppt.Patient__c == existing.Patient__c;

                if (overlaps &&
                    (sameDoctor || samePatient)) {

                    String message;

                    if (sameDoctor && samePatient) {
                        message =
                            'Conflict: this doctor and patient already have an overlapping appointment.';
                    }
                    else if (sameDoctor) {
                        message =
                            'Conflict: this doctor already has an overlapping appointment.';
                    }
                    else {
                        message =
                            'Conflict: this patient already has an overlapping appointment.';
                    }

                    newAppt.addError(message);

                    break;
                }
            }
        }
    }


    private static String buildMessage(
        List<Appointment__c> matches,
        Id doctorId,
        Id patientId
    ) {

        Boolean doctorBusy = false;
        Boolean patientBusy = false;

        for (Appointment__c row : matches) {

            if (row.Doctor__c == doctorId) {
                doctorBusy = true;
            }

            if (row.Patient__c == patientId) {
                patientBusy = true;
            }
        }

        if (doctorBusy && patientBusy) {

            return
                'Conflict: this doctor and patient already have an overlapping appointment.';
        }

        if (doctorBusy) {

            return
                'Conflict: this doctor already has an overlapping appointment.';
        }

        return
            'Conflict: this patient already has an overlapping appointment.';
    }
}