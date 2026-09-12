import { Component, OnInit } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { Setting } from '../setting.model';
import { SettingService } from '../setting.service';
import { SettingsService } from '../../../core/services/settings.service';

@Component({
  selector: 'app-general-settings',
  templateUrl: './general-settings.component.html',
  styleUrls: ['./general-settings.component.css']
})
export class GeneralSettingsComponent implements OnInit {
  loading = false;
  submitting = false;
  errorMessage = '';

  settingForm: Setting = this.createDefaultForm();
  private loadedSettingSnapshot: Setting = this.createDefaultForm();

  constructor(
    private settingService: SettingService,
    private settingsService: SettingsService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCurrentSetting();
  }

  loadCurrentSetting(): void {
    this.loading = true;
    this.errorMessage = '';

    this.settingService.getCurrentSetting().subscribe({
      next: (setting) => {
        this.settingForm = this.normalizeSetting(setting);
        this.loadedSettingSnapshot = { ...this.settingForm };
        this.loading = false;
      },
      error: (error: HttpErrorResponse) => {
        this.loading = false;
        if (error.status === 204 || error.status === 404) {
          this.settingForm = this.createDefaultForm();
          this.loadedSettingSnapshot = { ...this.settingForm };
          return;
        }

        this.settingForm = this.createDefaultForm();
        this.loadedSettingSnapshot = { ...this.settingForm };
        this.errorMessage = 'Failed to load settings.';
      }
    });
  }

  onSave(): void {
    this.errorMessage = '';

    if (!this.settingForm.storeName.trim() ||
        !this.settingForm.supportEmail.trim() ||
        !this.settingForm.currency.trim()) {
      this.errorMessage = 'Store Name, Support Email, and Currency are required.';
      return;
    }

    this.submitting = true;

    const payload: Setting = {
      ...this.settingForm,
      storeName: this.settingForm.storeName.trim(),
      storeTagline: (this.settingForm.storeTagline || '').trim(),
      supportEmail: this.settingForm.supportEmail.trim(),
      supportPhone: (this.settingForm.supportPhone || '').trim(),
      businessAddress: (this.settingForm.businessAddress || '').trim(),
      currency: this.settingForm.currency.trim(),
      taxRate: Number(this.settingForm.taxRate ?? 0),
      shippingCharge: Number(this.settingForm.shippingCharge ?? 0),
      orderPrefix: (this.settingForm.orderPrefix || '').trim(),
      invoicePrefix: (this.settingForm.invoicePrefix || '').trim(),
      paymentMethods: (this.settingForm.paymentMethods || '').trim(),
      logoUrl: (this.settingForm.logoUrl || '').trim(),
      faviconUrl: (this.settingForm.faviconUrl || '').trim(),
      maintenanceMode: !!this.settingForm.maintenanceMode,
      createdAt: this.settingForm.createdAt,
      updatedAt: this.settingForm.updatedAt
    };

    const request$ = payload.id
      ? this.settingService.updateSetting(payload.id, payload)
      : this.settingService.saveSetting(payload);

    request$.subscribe({
      next: (setting) => {
        this.settingForm = this.normalizeSetting(setting);
        this.loadedSettingSnapshot = { ...this.settingForm };
        this.settingsService.setSettings(this.settingForm);
        this.submitting = false;
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to save settings.';
      }
    });
  }

  onReset(): void {
    this.settingForm = { ...this.loadedSettingSnapshot };
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/dashboard']);
  }

  private createDefaultForm(): Setting {
    const today = new Date().toISOString().split('T')[0];

    return {
      id: 0,
      storeName: '',
      storeTagline: '',
      supportEmail: '',
      supportPhone: '',
      businessAddress: '',
      currency: 'BDT',
      taxRate: 0,
      shippingCharge: 0,
      orderPrefix: 'ORD',
      invoicePrefix: 'INV',
      paymentMethods: 'Cash, Card, Bank Transfer, Paypal',
      logoUrl: '',
      faviconUrl: '',
      maintenanceMode: false,
      createdAt: today,
      updatedAt: today
    };
  }

  private normalizeSetting(setting: Setting | null | undefined): Setting {
    const fallback = this.createDefaultForm();
    if (!setting) {
      return fallback;
    }

    return {
      id: Number(setting.id ?? 0),
      storeName: setting.storeName || '',
      storeTagline: setting.storeTagline || '',
      supportEmail: setting.supportEmail || '',
      supportPhone: setting.supportPhone || '',
      businessAddress: setting.businessAddress || '',
      currency: setting.currency || fallback.currency,
      taxRate: Number(setting.taxRate ?? 0),
      shippingCharge: Number(setting.shippingCharge ?? 0),
      orderPrefix: setting.orderPrefix || fallback.orderPrefix,
      invoicePrefix: setting.invoicePrefix || fallback.invoicePrefix,
      paymentMethods: setting.paymentMethods || fallback.paymentMethods,
      logoUrl: setting.logoUrl || '',
      faviconUrl: setting.faviconUrl || '',
      maintenanceMode: !!setting.maintenanceMode,
      createdAt: setting.createdAt || fallback.createdAt,
      updatedAt: setting.updatedAt || fallback.updatedAt
    };
  }
}
