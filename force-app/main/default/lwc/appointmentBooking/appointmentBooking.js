import { LightningElement, track } from 'lwc';

import checkAvailability
    from '@salesforce/apex/AppointmentController.checkAvailability';

import bookAppointment
    from '@salesforce/apex/AppointmentController.bookAppointment';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AppointmentBooking extends LightningElement {

    @track doctorId;
    @track patientId;
    @track appointmentDate;
    @track notes;

    isAvailable = false;
    isChecking = false;
    isBooking = false;

    // handleDoctorChange(event) {
    //     this.doctorId = event.detail.recordId;
    //     this.isAvailable = false;
    // }

    // handlePatientChange(event) {
    //     this.patientId = event.detail.recordId;
    //     this.isAvailable = false;
    // }

    handleDoctorChange(event) {

        this.doctorId =
            event.detail.recordId ||
            event.detail.value;

        this.isAvailable = false;

    }

    handlePatientChange(event) {

        this.patientId =
            event.detail.recordId ||
            event.detail.value;

        this.isAvailable = false;

    }

    handleDateChange(event) {

        this.appointmentDate = event.target.value;

        this.isAvailable = false;
    }

    handleNotesChange(event) {
        this.notes = event.target.recordId;
    }

    async handleCheckAvailability() {

        if (!this.doctorId ||
            !this.patientId ||
            !this.appointmentDate) {

            this.showToast(
                'Missing Information',
                'Please select doctor, patient and appointment date.',
                'warning'
            );

            return;
        }

        this.isChecking = true;

        try {

            const result = await checkAvailability({
                doctorId: this.doctorId,
                patientId: this.patientId,
                appointmentDate: this.appointmentDate
            });

            this.isAvailable = !result.hasConflict;

            this.showToast(
                result.hasConflict
                    ? 'Conflict'
                    : 'Available',
                result.message,
                result.hasConflict
                    ? 'error'
                    : 'success'
            );

        } catch (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );

        } finally {

            this.isChecking = false;
        }
    }

    async handleBook() {

        if (!this.isAvailable) {

            this.showToast(
                'Check Availability',
                'Please check availability before booking.',
                'warning'
            );

            return;
        }

        this.isBooking = true;

        try {

            const appointmentId = await bookAppointment({
                doctorId: this.doctorId,
                patientId: this.patientId,
                appointmentDate: this.appointmentDate,
                notes: this.notes
            });

            this.showToast(
                'Success',
                'Appointment booked successfully.',
                'success'
            );

            this.resetForm();

            this.dispatchEvent(
                new CustomEvent('appointmentcreated')
            );

        } catch (error) {

            this.showToast(
                'Booking Failed',
                this.getErrorMessage(error),
                'error'
            );

        } finally {

            this.isBooking = false;
        }
    }

    resetForm() {

        this.doctorId = null;
        this.patientId = null;
        this.appointmentDate = null;
        this.notes = null;
        this.isAvailable = false;
    }

    getErrorMessage(error) {

        if (error?.body?.message) {
            return error.body.message;
        }

        return 'An unexpected error occurred.';
    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}