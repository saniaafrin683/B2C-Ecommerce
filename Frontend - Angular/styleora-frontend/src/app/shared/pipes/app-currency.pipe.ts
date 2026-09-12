import { Pipe, PipeTransform } from '@angular/core';
import { formatNumber } from '@angular/common';
import { SettingsService } from '../../core/services/settings.service';

@Pipe({
  name: 'appCurrency',
  pure: false
})
export class AppCurrencyPipe implements PipeTransform {
  constructor(private settingsService: SettingsService) {}

  transform(value: number | string | null | undefined, digitsInfo = '1.2-2'): string {
    const amount = Number(value ?? 0);
    const safeAmount = Number.isFinite(amount) ? amount : 0;
    const currency = this.settingsService.getCurrency().trim();

    return `${currency}${currency === '৳' ? '' : ' '}${formatNumber(safeAmount, 'en-US', digitsInfo)}`;
  }
}
