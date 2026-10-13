import { LightningElement, wire } from 'lwc';

import getAppointments
    from '@salesforce/apex/AppointmentController.getAppointments';

import cancelAppointment
    from '@salesforce/apex/AppointmentController.cancelAppointment';

import completeAppointment
    from '@salesforce/apex/AppointmentController.completeAppointment';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { refreshApex } from '@salesforce/apex';

import rescheduleAppointment
    from '@salesforce/apex/AppointmentController.rescheduleAppointment';

export default class AppointmentList extends LightningElement {

    appointments = [];
    filteredAppointments = [];

    searchTerm = '';
    statusFilter = 'All';

    wiredAppointmentResult;

    isLoading = false;

    showRescheduleForm = false;
    selectedAppointmentId;
    newAppointmentDate;
    isRescheduling = false;


    @wire(getAppointments)
    wiredAppointments(result) {

        this.wiredAppointmentResult = result;

        const { data, error } = result;

        if (data) {

            this.appointments = data.map(
                appointment => ({
                    ...appointment,
                    canTakeAction:
                        appointment.Status__c !== 'Cancelled' && appointment.Status__c !== 'Completed', 
                    
                    formattedAppointmentDate: appointment.Appointment_Date__c
                        ? new Intl.DateTimeFormat('en-IN', {
                            timeZone: 'Asia/Kolkata',
                            day: '2-digit',
                            month: 'short',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                            hour12: true
                        }).format(new Date(appointment.Appointment_Date__c))
                        : ''
            })
            );
            this.applyFilters();

        } else if (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }


    get statusOptions() {

        return [
            { label: 'All', value: 'All' },
            { label: 'Scheduled', value: 'Scheduled' },
            { label: 'Completed', value: 'Completed' },
            { label: 'Cancelled', value: 'Cancelled' }
        ];
    }


    handleSearch(event) {

        this.searchTerm =
            event.target.value.toLowerCase();

        this.applyFilters();
    }


    handleStatusChange(event) {

        this.statusFilter =
            event.detail.value;

        this.applyFilters();
    }


    applyFilters() {

        let result = [...this.appointments];

        if (this.searchTerm) {

            result = result.filter(
                appointment => {

                    const patientName =
                        appointment.Patient__r?.Name
                        ?.toLowerCase() || '';

                    const doctorName =
                        appointment.Doctor__r?.Name
                        ?.toLowerCase() || '';

                    return (
                        patientName.includes(this.searchTerm) ||
                        doctorName.includes(this.searchTerm)
                    );
                }
            );
        }


        if (this.statusFilter !== 'All') {

            result = result.filter(
                appointment =>
                    appointment.Status__c ===
                    this.statusFilter
            );
        }

        this.filteredAppointments = result;
    }


    async handleCancel(event) {

        const appointmentId =
            event.currentTarget.dataset.id;

        if (!appointmentId) {
            return;
        }

        this.isLoading = true;

        try {

            await cancelAppointment({
                appointmentId
            });

            this.showToast(
                'Success',
                'Appointment cancelled.',
                'success'
            );

            await refreshApex(
                this.wiredAppointmentResult
            );

        } catch (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );

        } finally {

            this.isLoading = false;
        }
    }

    async handleComplete(event) {

        const appointmentId =
            event.currentTarget.dataset.id;

        if (!appointmentId) {
            return;
        }

        this.isLoading = true;

        try {

            await completeAppointment({
                appointmentId
            });

            this.showToast(
                'Success',
                'Appointment marked as completed.',
                'success'
            );

            await refreshApex(
                this.wiredAppointmentResult
            );

        } catch (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );

        } finally {

            this.isLoading = false;
        }
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

    handleRescheduleClick(event) {
        this.selectedAppointmentId =
            event.currentTarget.dataset.id;

        this.newAppointmentDate = null;
        this.showRescheduleForm = true;
    }

    handleNewDateChange(event) {
        this.newAppointmentDate = event.target.value;
    }

    handleRescheduleCancel() {
        this.showRescheduleForm = false;
        this.selectedAppointmentId = null;
        this.newAppointmentDate = null;
    }

    async handleRescheduleSave() {
        if (!this.newAppointmentDate) {
            this.showToast(
                'Missing Information',
                'Please select a new appointment date and time.',
                'warning'
            );
            return;
        }

        this.isRescheduling = true;

        try {
            await rescheduleAppointment({
                appointmentId: this.selectedAppointmentId,
                newAppointmentDate: this.newAppointmentDate
            });

            this.showToast(
                'Success',
                'Appointment rescheduled successfully.',
                'success'
            );

            this.handleRescheduleCancel();

            await refreshApex(this.wiredAppointmentResult);

        } catch (error) {
            this.showToast(
                'Rescheduling Failed',
                this.getErrorMessage(error),
                'error'
            );
        } finally {
            this.isRescheduling = false;
        }
    }
}