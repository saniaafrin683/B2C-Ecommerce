import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';

import { environment } from '../../../environments/environment';

export interface ReturnRequest {
  id: number;
  orderId: number;
  customerId: number;
  productId?: number | null;
  reason: string;
  note: string;
  status: string;
  requestedAt: string;
  updatedAt: string;
  orderReference?: string;
  customerName?: string;
}

export interface ReturnRequestPayload {
  orderId: number;
  customerId?: number | null;
  productId?: number | null;
  reason: string;
  note?: string;
}

interface ReturnRequestApiModel {
  id?: number;
  orderId?: number;
  customerId?: number;
  productId?: number | null;
  reason?: string;
  note?: string;
  remarks?: string;
  status?: string;
  requestedAt?: string;
  requestedDate?: string;
  updatedAt?: string;
  orderReference?: string;
  customerName?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ReturnRequestService {
  private readonly baseUrl = `${environment.apiBaseUrl}/returns`;

  constructor(private readonly http: HttpClient) {}

  getCustomerReturnRequests(customerId: number): Observable<ReturnRequest[]> {
    return this.http.get<ReturnRequestApiModel[]>(`${this.baseUrl}/customer/${customerId}`).pipe(
      map((requests) => (requests || []).map((request) => this.toReturnRequest(request)))
    );
  }

  requestReturn(payload: ReturnRequestPayload): Observable<ReturnRequest> {
    return this.http.post<ReturnRequestApiModel>(`${this.baseUrl}/request`, payload).pipe(
      map((request) => this.toReturnRequest(request))
    );
  }

  private toReturnRequest(request: ReturnRequestApiModel): ReturnRequest {
    return {
      id: Number(request.id ?? 0),
      orderId: Number(request.orderId ?? 0),
      customerId: Number(request.customerId ?? 0),
      productId: this.normalizeNullableId(request.productId),
      reason: request.reason || '',
      note: request.note || request.remarks || '',
      status: request.status || 'Pending',
      requestedAt: request.requestedAt || request.requestedDate || '',
      updatedAt: request.updatedAt || '',
      orderReference: request.orderReference || '',
      customerName: request.customerName || ''
    };
  }

  private normalizeNullableId(value: number | string | null | undefined): number | null {
    const normalized = Number(value);
    return Number.isFinite(normalized) && normalized > 0 ? normalized : null;
  }
}
