import { LightningElement, track, wire } from 'lwc';
import getSpecializations from '@salesforce/apex/AppointmentController.getSpecializations';

export default class SpecializationPicker extends LightningElement {

    @track specializations = [];
    @track selectedKey     = null;
    @track errorMessage    = '';
    isLoading              = true;

    // ─── Wire ────────────────────────────────────────────────────────────────

    @wire(getSpecializations)
    wiredSpecializations({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.specializations = data.map(s => ({
                key   : s.DeveloperName,
                label : s.MasterLabel,
                price : s.Price__c
            }));
        } else if (error) {
            this.errorMessage = error?.body?.message || 'Failed to load specializations.';
        }
    }

    // ─── Getters ─────────────────────────────────────────────────────────────

    get hasError() {
        return !!this.errorMessage;
    }

    get enrichedSpecializations() {
        return this.specializations.map(s => ({
            ...s,
            cssClass : s.key === this.selectedKey
                ? 'spec-card spec-card--selected'
                : 'spec-card'
        }));
    }

    // ─── Handlers ────────────────────────────────────────────────────────────

    handleSelect(event) {
        const { key, label, price } = event.currentTarget.dataset;
        this.selectedKey = key;

        this.dispatchEvent(new CustomEvent('specializationselected', {
            detail   : { specialization: key, label, price: Number(price) },
            bubbles  : false,
            composed : false
        }));
    }
}
