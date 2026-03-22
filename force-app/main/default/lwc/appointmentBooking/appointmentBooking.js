import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Contact.Name';
import createAppointment from '@salesforce/apex/AppointmentController.createAppointment';
import getPatientRecordTypeId from '@salesforce/apex/AppointmentController.getPatientRecordTypeId';

export default class AppointmentBooking extends LightningElement {

    /** IANA timezone — configurable in App Builder. */
    @api timeZone = 'Europe/London';

    _patientRecordTypeId = null;
    @track selectedPatientId = null;
    @track selectedPatientName = '';
    @track selectedSpecialization = null;
    @track selectedSpecializationLabel = '';
    @track selectedPrice = 0;
    @track selectedDoctorId = null;
    @track selectedCalendarId = null;
    @track selectedDoctorName = '';
    @track selectedSlot = null;
    @track isBooking = false;

    @wire(getPatientRecordTypeId)
    wiredPatientRTId({ data }) {
        if (data) this._patientRecordTypeId = data;
    }

    @wire(getRecord, { recordId: '$selectedPatientId', fields: [NAME_FIELD] })
    wiredPatient({ data, error }) {
        if (data) this.selectedPatientName = data.fields.Name.value;
        if (error) this.selectedPatientName = '';
    }

    // Filter lightning-record-picker to Patient record type only.
    // Uses RecordTypeId directly — relationship traversal like RecordType.DeveloperName
    // is not supported by the record picker filter API.
    get patientFilter() {
        if (!this._patientRecordTypeId) return {};
        return {
            criteria: [{
                fieldPath: 'RecordTypeId',
                operator: 'eq',
                value: this._patientRecordTypeId
            }]
        };
    }

    get showBookingSummary() {
        return !!this.selectedSlot;
    }

    get noPatientSelected() {
        return !this.selectedPatientId;
    }

    get isConfirmDisabled() {
        return this.isBooking || !this.selectedPatientId;
    }

    get bookButtonLabel() {
        return this.isBooking ? 'Booking…' : 'Confirm Booking';
    }

    get bookingDateTimeLabel() {
        if (!this.selectedSlot) return '';
        return this.selectedSlot.label + ', ' + this._formatDate(this.selectedSlot.date);
    }

    handlePatientChange(event) {
        this.selectedPatientId = event.detail.recordId ?? null;
        if (!this.selectedPatientId) this.selectedPatientName = '';
    }

    handleSpecializationSelected(event) {
        const { specialization, label, price } = event.detail;
        this.selectedSpecialization = specialization;
        this.selectedSpecializationLabel = label;
        this.selectedPrice = price;
        // Reset downstream
        this.selectedDoctorId = null;
        this.selectedCalendarId = null;
        this.selectedDoctorName = '';
        this.selectedSlot = null;
    }

    handleDoctorSelected(event) {
        const { doctorId, calendarId, doctorName } = event.detail;
        this.selectedDoctorId = doctorId;
        this.selectedCalendarId = calendarId;
        this.selectedDoctorName = doctorName;
        // Reset slot
        this.selectedSlot = null;
    }

    handleSlotSelected(event) {
        this.selectedSlot = event.detail;
    }

    handleConfirmBooking() {
        if (!this.selectedPatientId) return;
        this.isBooking = true;

        createAppointment({
            doctorId: this.selectedDoctorId,
            patientId: this.selectedPatientId,
            specialization: this.selectedSpecialization,
            price: this.selectedPrice,
            calendarId: this.selectedCalendarId,
            startIso: this.selectedSlot.startIso,
            endIso: this.selectedSlot.endIso,
            timeZone: this.timeZone,
            notes: null
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Appointment Booked!',
                message: this.selectedDoctorName + ' — '
                    + this.selectedSlot.label + ', '
                    + this._formatDate(this.selectedSlot.date),
                variant: 'success'
            }));
            this._resetForm();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Booking Failed',
                message: error?.body?.message || 'An unexpected error occurred.',
                variant: 'error',
                mode: 'sticky'
            }));
        })
        .finally(() => {
            this.isBooking = false;
        });
    }

    _resetForm() {
        this.selectedPatientId = null;
        this.selectedPatientName = '';
        this.selectedSpecialization = null;
        this.selectedSpecializationLabel = '';
        this.selectedPrice = 0;
        this.selectedDoctorId = null;
        this.selectedCalendarId = null;
        this.selectedDoctorName = '';
        this.selectedSlot = null;

        // Clear the record picker
        const picker = this.template.querySelector('lightning-record-picker');
        if (picker) picker.clearSelection();
    }

    _formatDate(dateStr) {
        if (!dateStr) return '';
        // Use T12:00 to avoid off-by-one day in any UTC-adjacent timezone
        const d = new Date(dateStr + 'T12:00:00');
        return d.toLocaleDateString('en-GB', {
            day: 'numeric', month: 'short', year: 'numeric'
        });
    }
}
