import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { ReturnRequest } from './return-request.model';
import { environment } from '../../../environments/environment';

interface ReturnRequestApiModel {
  id?: number;
  orderId?: number;
  customerId?: number;
  productId?: number | null;
  orderReference?: string;
  customerName?: string;
  reason?: string;
  note?: string;
  remarks?: string;
  status?: string;
  requestedAt?: string;
  requestedDate?: string;
  updatedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ReturnRequestService {
  private readonly baseUrl = `${environment.apiBaseUrl}/returns`;

  constructor(private http: HttpClient) {}

  getReturnRequests(): Observable<ReturnRequest[]> {
    return this.http.get<ReturnRequestApiModel[]>(this.baseUrl).pipe(
      map((requests) => (requests || []).map((request) => this.toFrontendModel(request)))
    );
  }

  getReturnRequestById(id: number): Observable<ReturnRequest> {
    return this.http.get<ReturnRequestApiModel>(`${this.baseUrl}/${id}`).pipe(
      map((request) => this.toFrontendModel(request))
    );
  }

  createReturnRequest(returnRequest: ReturnRequest): Observable<ReturnRequest> {
    return this.http.post<ReturnRequestApiModel>(`${this.baseUrl}/create`, this.toCreatePayload(returnRequest)).pipe(
      map((request) => this.toFrontendModel(request))
    );
  }

  updateReturnRequestStatus(id: number, status: string, note?: string): Observable<ReturnRequest> {
    return this.http.put<ReturnRequestApiModel>(`${this.baseUrl}/status/${id}`, { status, note }).pipe(
      map((request) => this.toFrontendModel(request))
    );
  }

  updateReturnRequest(id: number, returnRequest: ReturnRequest): Observable<ReturnRequest> {
    return this.updateReturnRequestStatus(id, returnRequest.status, returnRequest.note);
  }

  deleteReturnRequest(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  private toFrontendModel(request: ReturnRequestApiModel): ReturnRequest {
    return {
      id: Number(request.id ?? 0),
      orderId: Number(request.orderId ?? 0),
      customerId: Number(request.customerId ?? 0),
      productId: this.normalizeNullableId(request.productId),
      orderReference: request.orderReference || '',
      customerName: request.customerName || '',
      reason: request.reason || '',
      note: request.note || request.remarks || '',
      status: request.status || 'Pending',
      requestedAt: request.requestedAt || request.requestedDate || '',
      updatedAt: request.updatedAt || ''
    };
  }

  private toCreatePayload(returnRequest: ReturnRequest): object {
    return {
      orderId: Number(returnRequest.orderId ?? 0),
      customerId: Number(returnRequest.customerId ?? 0),
      productId: this.normalizeNullableId(returnRequest.productId),
      reason: (returnRequest.reason || '').trim(),
      note: (returnRequest.note || '').trim()
    };
  }

  private normalizeNullableId(value: number | string | null | undefined): number | null {
    const normalized = Number(value);
    return Number.isFinite(normalized) && normalized > 0 ? normalized : null;
  }
}
