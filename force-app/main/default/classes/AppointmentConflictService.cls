/**
 * Finds overlapping Appointment__c records for a doctor or patient.
 *
 * Appointment__c only has Appointment_Date__c (start time), not an end time,
 * so each booking is treated as a 30-minute slot:
 *   [Appointment_Date__c, Appointment_Date__c + 30 minutes).
 *
 * Example: 10:00 conflicts with 10:15. 10:30 is allowed (back-to-back).
 * Cancelled appointments are ignored so that slot can be reused.
 */
public with sharing class AppointmentConflictService {
    // Default length of one appointment in minutes.
    public static final Integer SLOT_MINUTES = 30;

    /**
     * Wrapper returned to LWC. @AuraEnabled is required so JavaScript
     * can read these properties from the Apex result.
     */
    public class ConflictResult {
        @AuraEnabled public Boolean hasConflict;
        @AuraEnabled public String message;
        @AuraEnabled public List<Appointment__c> conflictingAppointments;
    }

    /**
     * Read-only check used by the LWC "Check availability" button.
     * cacheable=true allows Lightning to cache the result.
     *
     * excludeAppointmentId: pass the current record Id on update so the
     * appointment does not conflict with itself. Pass null for a new booking.
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
        result.conflictingAppointments = new List<Appointment__c>();

        if (doctorId == null || patientId == null || appointmentDate == null) {
            result.message = 'Doctor, Patient, and Appointment Date are required.';
            return result;
        }

        // Two 30-minute slots overlap when the other start is strictly inside
        // (requestedStart - 30 minutes, requestedStart + 30 minutes).
        Datetime windowStart = appointmentDate.addMinutes(-SLOT_MINUTES);
        Datetime windowEnd = appointmentDate.addMinutes(SLOT_MINUTES);

        List<Appointment__c> matches = [
            SELECT Id, Name, Doctor__c, Patient__c, Appointment_Date__c, Status__c
            FROM Appointment__c
            WHERE Status__c != 'Cancelled'
            AND Appointment_Date__c > :windowStart
            AND Appointment_Date__c < :windowEnd
            AND (Doctor__c = :doctorId OR Patient__c = :patientId)
            AND Id != :excludeAppointmentId
        ];

        if (!matches.isEmpty()) {
            result.hasConflict = true;
            result.conflictingAppointments = matches;
            result.message = buildMessage(matches, doctorId, patientId);
        } else {
            result.message = 'Slot is available.';
        }
        return result;
    }

    /**
     * Called by the LWC Save button. Checks the slot, then inserts.
     * Not cacheable because it performs DML (insert).
     */
    @AuraEnabled
    public static Id createAppointment(
        Id doctorId,
        Id patientId,
        Datetime appointmentDate,
        String notes
    ) {
        ConflictResult check = checkConflicts(doctorId, patientId, appointmentDate, null);
        if (check.hasConflict) {
            // AuraHandledException is how Apex sends a user-facing error to LWC.
            throw new AuraHandledException(check.message);
        }

        Appointment__c appt = new Appointment__c(
            Doctor__c = doctorId,
            Patient__c = patientId,
            Appointment_Date__c = appointmentDate,
            Status__c = 'Scheduled',
            Notes__c = notes
        );
        insert appt;
        return appt.Id;
    }

    /**
     * Called from AppointmentConflictTrigger (before insert / before update).
     * Blocks save from the standard New Appointment screen, API, and Data Loader,
     * not only from the LWC.
     */
    public static void validateAppointments(List<Appointment__c> appointments) {
        for (Appointment__c appt : appointments) {
            // Cancelled rows are not a live booking, so skip conflict checks.
            if (appt.Status__c == 'Cancelled') {
                continue;
            }
            ConflictResult check = checkConflicts(
                appt.Doctor__c,
                appt.Patient__c,
                appt.Appointment_Date__c,
                appt.Id
            );
            if (check.hasConflict) {
                // addError stops that record from saving and shows the message.
                appt.addError(check.message);
            }
        }
    }

    // Builds a short reason: doctor busy, patient busy, or both.
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
            return 'Conflict: this doctor and patient already have an overlapping appointment.';
        }
        if (doctorBusy) {
            return 'Conflict: this doctor already has an overlapping appointment.';
        }
        return 'Conflict: this patient already has an overlapping appointment.';
    }
}
