import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';
import { CurrentStockSummary } from './current-stock.model';

@Injectable({
  providedIn: 'root'
})
export class CurrentStockService {
  private readonly baseUrl = `${environment.apiBaseUrl}/inventory/current-stock`;

  constructor(private http: HttpClient) {}

  getCurrentStock(): Observable<CurrentStockSummary[]> {
    return this.http.get<CurrentStockSummary[]>(this.baseUrl).pipe(
      map((items) => (items || []).map((item) => this.normalizeItem(item)))
    );
  }

  private normalizeItem(item: CurrentStockSummary): CurrentStockSummary {
    return {
      productId: Number(item?.productId ?? 0),
      productName: (item?.productName || '').trim(),
      category: (item?.category || '').trim(),
      currentStock: this.normalizeNumber(item?.currentStock),
      totalSold: this.normalizeNumber(item?.totalSold),
      totalPurchased: this.normalizeNumber(item?.totalPurchased),
      stockStatus: (item?.stockStatus || '').trim() || this.resolveStockStatus(item?.currentStock)
    };
  }

  private normalizeNumber(value: number | string | null | undefined): number {
    const normalized = Number(value ?? 0);
    return Number.isFinite(normalized) ? normalized : 0;
  }

  private resolveStockStatus(stock: number | string | null | undefined): string {
    const normalizedStock = this.normalizeNumber(stock);
    if (normalizedStock <= 0) {
      return 'Out of Stock';
    }
    if (normalizedStock < 10) {
      return 'Low Stock';
    }
    return 'In Stock';
  }
}
