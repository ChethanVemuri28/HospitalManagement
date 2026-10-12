public with sharing class DoctorAvailabilityService {

    public class AvailabilityResult {
        @AuraEnabled public Boolean isAvailable;
        @AuraEnabled public String message;
    }

    public static AvailabilityResult checkAvailability(
        Id doctorId,
        Datetime appointmentDate
    ) {
        AvailabilityResult result = new AvailabilityResult();
        result.isAvailable = false;

        if (doctorId == null || appointmentDate == null) {
            result.message =
                'Doctor and appointment date are required.';
            return result;
        }

        String dayName = appointmentDate.format('EEEE');

        List<Doctor_Availability__c> schedules = [
            SELECT Id, Day_of_Week__c, Start_Time__c,
                   End_Time__c, Is_available__c
            FROM Doctor_Availability__c
            WHERE Doctor__c = :doctorId
            AND Day_of_Week__c INCLUDES (:dayName)
            LIMIT 1
        ];

        if (schedules.isEmpty()) {
            result.message =
                'No working hours configured for this doctor on '
                + dayName + '.';
            return result;
        }

        Doctor_Availability__c schedule = schedules[0];

        if (schedule.Is_available__c != true) {
            result.message =
                'This doctor is unavailable on ' + dayName + '.';
            return result;
        }

        if (schedule.Start_Time__c == null ||
            schedule.End_Time__c == null) {
            result.message =
                'The doctor’s working hours are incomplete.';
            return result;
        }

        Datetime appointmentEnd =
            appointmentDate.addMinutes(30);

        Time appointmentStartTime = Time.newInstance(
            Integer.valueOf(appointmentDate.format('HH')),
            Integer.valueOf(appointmentDate.format('mm')),
            0, 0
        );

        Time appointmentEndTime = Time.newInstance(
            Integer.valueOf(appointmentEnd.format('HH')),
            Integer.valueOf(appointmentEnd.format('mm')),
            0, 0
        );

        if (appointmentStartTime < schedule.Start_Time__c ||
            appointmentEndTime > schedule.End_Time__c ||
            appointmentEnd.date() != appointmentDate.date()) {
            result.message =
                'Appointment must fit within the doctor’s working hours.';
            return result;
        }

        result.isAvailable = true;
        result.message =
            'Doctor is available during this time.';

        return result;
    }
}