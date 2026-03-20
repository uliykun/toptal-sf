import { LightningElement, api, track, wire } from 'lwc';
import getDoctorsBySpecialization from '@salesforce/apex/AppointmentController.getDoctorsBySpecialization';

export default class DoctorPicker extends LightningElement {

    @track _specialization = null;
    @track doctors = [];
    @track selectedId = null;
    @track errorMessage = '';
    isLoading = false;

    @api
    get specialization() {
        return this._specialization;
    }
    set specialization(value) {
        this._specialization = value;
        this.selectedId = null;   // reset selection when specialization changes
        this.errorMessage = '';
    }

    @wire(getDoctorsBySpecialization, { specialization: '$_specialization' })
    wiredDoctors({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.doctors = data.map(doc => ({
                id: doc.Id,
                fullName: 'Dr. ' + doc.FirstName + ' ' + doc.LastName,
                email: doc.Email,
                calendarId: doc.Google_Calendar_Id__c
            }));
        } else if (error) {
            this.errorMessage = error?.body?.message || 'Failed to load doctors.';
        }
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.doctors.length === 0;
    }

    get enrichedDoctors() {
        return this.doctors.map(doc => ({
            ...doc,
            cssClass: doc.id === this.selectedId
                ? 'doctor-card doctor-card--selected'
                : 'doctor-card'
        }));
    }

    handleSelect(event) {
        const { id, calendarId, name } = event.currentTarget.dataset;
        this.selectedId = id;

        this.dispatchEvent(new CustomEvent('doctorselected', {
            detail: { doctorId: id, calendarId, doctorName: name },
            bubbles: false,
            composed: false
        }));
    }
}
