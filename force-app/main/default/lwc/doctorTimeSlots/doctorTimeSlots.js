import { LightningElement, api, track } from 'lwc';
import getAvailableSlots from '@salesforce/apex/GoogleCalendarController.getAvailableSlots';

export default class DoctorTimeSlots extends LightningElement {
    // Calendar ID of the physician (e.g. 'primary' or a full Gmail address)
    @api calendarId = 'primary';
    // IANA timezone identifier (e.g. 'Europe/London')
    @api timeZone = 'Europe/London';

    @track slots = [];
    @track selectedDate = '';
    @track selectedSlot = null;
    @track isLoading = false;
    @track errorMessage = '';

    // today's date as YYYY-MM-DD in local time (used as date input min)
    get today() {
        const now   = new Date();
        const year  = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day   = String(now.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    get noDateSelected() {
        return !this.selectedDate;
    }

    get hasError() {
        return !!this.errorMessage && !this.isLoading;
    }

    get hasSlots() {
        return this.slots.length > 0 && !this.isLoading && !this.errorMessage;
    }

    // e.g. "Friday, 20 March 2026"
    get slotDateLabel() {
        if (!this.selectedDate) return '';
        // Use T12:00:00 to avoid timezone-boundary day-off issues
        const date = new Date(this.selectedDate + 'T12:00:00');
        return date.toLocaleDateString('en-GB', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    // adds CSS class and booked flag to each slot for template rendering
    get enrichedSlots() {
        return this.slots.map(slot => ({
            ...slot,
            isBooked: !slot.isAvailable,
            cssClass: this._slotCssClass(slot)
        }));
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.selectedSlot = null;
        this.errorMessage = '';
        if (this.selectedDate) {
            this._fetchSlots();
        }
    }

    handleSlotClick(event) {
        const { start, end, label } = event.currentTarget.dataset;
        this.selectedSlot = { startIso: start, endIso: end, label };

        // notify parent booking wizard
        this.dispatchEvent(new CustomEvent('slotselected', {
            detail: {
                startIso: start,
                endIso: end,
                label: label,
                date: this.selectedDate
            },
            bubbles: false,
            composed: false
        }));
    }

    _fetchSlots() {
        this.isLoading = true;
        this.slots = [];

        getAvailableSlots({
            calendarId: this.calendarId,
            dateStr: this.selectedDate,
            timeZone: this.timeZone
        })
            .then(result => {
                this.slots = result;
                this.errorMessage = '';
            })
            .catch(error => {
                this.errorMessage =
                    error?.body?.message ||
                    'Failed to load available slots. Please try again.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    _slotCssClass(slot) {
        const base = 'slot-btn';
        if (!slot.isAvailable) return `${base} slot-btn--booked`;
        if (this.selectedSlot?.startIso === slot.startIso) return `${base} slot-btn--selected`;
        return `${base} slot-btn--available`;
    }
}
