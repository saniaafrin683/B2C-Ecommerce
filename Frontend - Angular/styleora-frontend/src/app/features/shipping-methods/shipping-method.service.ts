import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ShippingMethod } from './shipping-method.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ShippingMethodService {
  private readonly baseUrl = `${environment.apiBaseUrl}/shipping-methods`;

  constructor(private http: HttpClient) {}

  getShippingMethods(): Observable<ShippingMethod[]> {
    return this.http.get<ShippingMethod[]>(`${this.baseUrl}/list`).pipe(
      map((shippingMethods) => (shippingMethods || []).map((item) => this.normalizeShippingMethod(item)))
    );
  }

  getShippingMethodById(id: number): Observable<ShippingMethod> {
    return this.http.get<ShippingMethod>(`${this.baseUrl}/${id}`).pipe(
      map((shippingMethod) => this.normalizeShippingMethod(shippingMethod))
    );
  }

  createShippingMethod(shippingMethod: ShippingMethod): Observable<ShippingMethod> {
    return this.http.post<ShippingMethod>(`${this.baseUrl}/create`, this.toApiPayload(shippingMethod)).pipe(
      map((response) => this.normalizeShippingMethod(response))
    );
  }

  updateShippingMethod(id: number, shippingMethod: ShippingMethod): Observable<ShippingMethod> {
    return this.http.put<ShippingMethod>(`${this.baseUrl}/update/${id}`, this.toApiPayload(shippingMethod)).pipe(
      map((response) => this.normalizeShippingMethod(response))
    );
  }

  deleteShippingMethod(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  private toApiPayload(shippingMethod: ShippingMethod): ShippingMethod {
    return {
      ...shippingMethod,
      name: (shippingMethod.name || '').trim(),
      description: (shippingMethod.description || '').trim(),
      coverageArea: (shippingMethod.coverageArea || '').trim(),
      courierName: (shippingMethod.courierName || '').trim(),
      cost: Number(shippingMethod.cost ?? 0),
      minOrderAmount: Number(shippingMethod.minOrderAmount ?? 0),
      maxWeightKg: Number(shippingMethod.maxWeightKg ?? 0),
      isFreeShipping: !!shippingMethod.isFreeShipping,
      estimatedDays: Number(shippingMethod.estimatedDays ?? 0),
      sortOrder: Number(shippingMethod.sortOrder ?? 0),
      status: this.normalizeStatus(shippingMethod.status)
    };
  }

  private normalizeShippingMethod(shippingMethod: ShippingMethod | null | undefined): ShippingMethod {
    return {
      id: Number(shippingMethod?.id ?? 0),
      name: shippingMethod?.name || '',
      description: shippingMethod?.description || '',
      coverageArea: shippingMethod?.coverageArea || '',
      courierName: shippingMethod?.courierName || '',
      cost: Number(shippingMethod?.cost ?? 0),
      minOrderAmount: Number(shippingMethod?.minOrderAmount ?? 0),
      maxWeightKg: Number(shippingMethod?.maxWeightKg ?? 0),
      isFreeShipping: !!shippingMethod?.isFreeShipping,
      estimatedDays: Number(shippingMethod?.estimatedDays ?? 0),
      sortOrder: Number(shippingMethod?.sortOrder ?? 0),
      status: this.normalizeStatus(shippingMethod?.status)
    };
  }

  private normalizeStatus(value: string | null | undefined): string {
    const rawStatus = (value || '').trim().toUpperCase();
    return rawStatus === 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
  }
}
