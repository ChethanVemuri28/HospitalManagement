import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// Import Apex methods so this LWC can call AppointmentConflictService.
import checkConflicts from '@salesforce/apex/AppointmentConflictService.checkConflicts';
import createAppointment from '@salesforce/apex/AppointmentConflictService.createAppointment';

/**
 * Booking form shown on a Lightning page.
 * User picks a doctor, patient, and datetime, then either checks the slot
 * or saves. Save also re-checks conflicts in Apex before insert.
 */
export default class AppointmentBooking extends NavigationMixin(LightningElement) {
    // Ids returned by lightning-record-picker (Doctor__c / Patient__c).
    doctorId;
    patientId;
    // Value from lightning-input type="datetime" (ISO datetime string).
    appointmentDate;
    notes;
    // Text shown under the form after Check or a failed Save.
    conflictMessage;
    // True while Save is running so the user cannot double-click.
    isBusy = false;

    // Store the selected doctor and clear any old conflict message.
    handleDoctorChange(event) {
        this.doctorId = event.detail.recordId;
        this.clearConflict();
    }

    handlePatientChange(event) {
        this.patientId = event.detail.recordId;
        this.clearConflict();
    }

    handleDateChange(event) {
        this.appointmentDate = event.target.value;
        this.clearConflict();
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
    }

    // Hide the previous availability/conflict text when the user changes inputs.
    clearConflict() {
        this.conflictMessage = undefined;
    }

    // True when doctor, patient, and date are set and Save is not in progress.
    get canSubmit() {
        return this.doctorId && this.patientId && this.appointmentDate && !this.isBusy;
    }

    // Used by the HTML disabled attribute on the Save button.
    get cannotSubmit() {
        return !(this.doctorId && this.patientId && this.appointmentDate) || this.isBusy;
    }

    // Read-only check: does NOT insert a record. Calls Apex checkConflicts.
    async handleCheck() {
        this.conflictMessage = undefined;
        try {
            const result = await checkConflicts({
                doctorId: this.doctorId,
                patientId: this.patientId,
                appointmentDate: this.appointmentDate,
                // null = this is a new booking, so do not exclude any existing Id.
                excludeAppointmentId: null
            });
            this.conflictMessage = result.message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: result.hasConflict ? 'Conflict' : 'Available',
                    message: result.message,
                    variant: result.hasConflict ? 'error' : 'success'
                })
            );
        } catch (e) {
            this.showError(e);
        }
    }

    // Inserts the appointment. Apex checks conflicts again, then insert.
    async handleSave() {
        this.isBusy = true;
        try {
            const id = await createAppointment({
                doctorId: this.doctorId,
                patientId: this.patientId,
                appointmentDate: this.appointmentDate,
                notes: this.notes
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Appointment created',
                    message: 'Record saved successfully.',
                    variant: 'success'
                })
            );
            // Open the new Appointment record page after a successful save.
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: id,
                    objectApiName: 'Appointment__c',
                    actionName: 'view'
                }
            });
        } catch (e) {
            // Apex throws AuraHandledException when the slot is already taken.
            this.conflictMessage = this.reduceError(e);
            this.showError(e);
        } finally {
            this.isBusy = false;
        }
    }

    showError(e) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: this.reduceError(e),
                variant: 'error'
            })
        );
    }

    // Apex errors usually live on e.body.message; fall back to e.message.
    reduceError(e) {
        if (e?.body?.message) {
            return e.body.message;
        }
        return e?.message || 'Unknown error';
    }
}
