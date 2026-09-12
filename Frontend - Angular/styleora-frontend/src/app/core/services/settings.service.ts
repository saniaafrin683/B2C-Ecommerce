import { Inject, Injectable } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, firstValueFrom, of } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { Setting } from '../../features/settings/setting.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SettingsService {
  private readonly baseUrl = `${environment.apiBaseUrl}/settings`;
  private readonly defaultFaviconPath = 'favicon.ico';
  private readonly defaultSettings = this.createDefaultSettings();
  private readonly settingsSubject = new BehaviorSubject<Setting>(this.defaultSettings);

  readonly settings$ = this.settingsSubject.asObservable();

  constructor(
    private http: HttpClient,
    @Inject(DOCUMENT) private document: Document
  ) {}

  loadSettings(): Promise<void> {
    return firstValueFrom(
      this.http.get<Setting | null>(this.baseUrl).pipe(
        tap((settings) => this.setSettings(settings)),
        catchError(() => {
          this.setSettings(null);
          return of(null);
        })
      )
    ).then(() => undefined);
  }

  setSettings(settings: Setting | null | undefined): void {
    const normalized = this.normalizeSettings(settings);
    this.settingsSubject.next(normalized);
    this.applyFavicon(normalized.faviconUrl);
  }

  getCurrentSettings(): Setting {
    return this.settingsSubject.value;
  }

  getCurrency(): string {
    return this.normalizeCurrency(this.getCurrentSettings().currency);
  }

  getOrderPrefix(): string {
    return this.getCurrentSettings().orderPrefix || this.defaultSettings.orderPrefix;
  }

  getInvoicePrefix(): string {
    return this.getCurrentSettings().invoicePrefix || this.defaultSettings.invoicePrefix;
  }

  private normalizeSettings(settings: Setting | null | undefined): Setting {
    const fallback = this.defaultSettings;

    if (!settings) {
      return { ...fallback };
    }

    return {
      id: Number(settings.id ?? 0),
      storeName: settings.storeName || fallback.storeName,
      storeTagline: settings.storeTagline || fallback.storeTagline,
      supportEmail: settings.supportEmail || fallback.supportEmail,
      supportPhone: settings.supportPhone || fallback.supportPhone,
      businessAddress: settings.businessAddress || fallback.businessAddress,
      currency: this.normalizeCurrency(settings.currency),
      taxRate: Number(settings.taxRate ?? fallback.taxRate),
      shippingCharge: Number(settings.shippingCharge ?? fallback.shippingCharge),
      orderPrefix: settings.orderPrefix || fallback.orderPrefix,
      invoicePrefix: settings.invoicePrefix || fallback.invoicePrefix,
      paymentMethods: settings.paymentMethods || fallback.paymentMethods,
      logoUrl: settings.logoUrl || '',
      faviconUrl: settings.faviconUrl || '',
      maintenanceMode: !!settings.maintenanceMode,
      createdAt: settings.createdAt || fallback.createdAt,
      updatedAt: settings.updatedAt || fallback.updatedAt
    };
  }

  private normalizeCurrency(currency: string | null | undefined): string {
    const value = (currency || '').trim();

    if (!value) {
      return this.defaultSettings.currency;
    }

    if (value.includes('৳')) {
      return '৳';
    }

    const alphaCode = value.match(/[A-Za-z]{3}/);
    if (alphaCode) {
      return alphaCode[0].toUpperCase();
    }

    return this.defaultSettings.currency;
  }

  private applyFavicon(faviconUrl: string): void {
    const faviconLink = this.document.getElementById('appFavicon') as HTMLLinkElement | null;
    if (!faviconLink) {
      return;
    }

    const nextFaviconUrl = (faviconUrl || '').trim();
    if (!nextFaviconUrl) {
      faviconLink.href = this.defaultFaviconPath;
      return;
    }

    const probeImage = new Image();
    probeImage.onload = () => {
      faviconLink.href = nextFaviconUrl;
    };
    probeImage.onerror = () => {
      faviconLink.href = this.defaultFaviconPath;
    };
    probeImage.src = nextFaviconUrl;
  }

  private createDefaultSettings(): Setting {
    const today = new Date().toISOString().split('T')[0];

    return {
      id: 0,
      storeName: 'StyleOra',
      storeTagline: 'Fashion Commerce',
      supportEmail: '',
      supportPhone: '',
      businessAddress: '',
      currency: 'BDT',
      taxRate: 0,
      shippingCharge: 0,
      orderPrefix: 'ORD',
      invoicePrefix: 'INV',
      paymentMethods: '',
      logoUrl: '',
      faviconUrl: '',
      maintenanceMode: false,
      createdAt: today,
      updatedAt: today
    };
  }
}
