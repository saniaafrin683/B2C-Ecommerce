import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { ReceivedOrder } from './received-order.model';
import { environment } from '../../../../environments/environment';

interface ReceivedOrderApiModel {
  id?: number;
  orderNo?: string;
  orderNumber?: string;
  supplierName?: string;
  warehouseId?: number | null;
  warehouseName?: string;
  productId?: number | null;
  productName?: string;
  quantity?: number;
  receivedDate?: string;
  status?: string;
  totalAmount?: number;
  createdAt?: string;
  updatedAt?: string;
  stockApplied?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ReceivedOrderService {

  private readonly baseUrl = `${environment.apiBaseUrl}/inventory/received-orders`;

  constructor(private http: HttpClient) {}

  getAllReceivedOrders(): Observable<ReceivedOrder[]> {
    return this.http.get<ReceivedOrderApiModel[]>(this.baseUrl).pipe(
      map((orders) => (orders || []).map((order) => this.toFrontendOrder(order)))
    );
  }

  getReceivedOrderById(id: number): Observable<ReceivedOrder> {
    return this.http.get<ReceivedOrderApiModel>(`${this.baseUrl}/${id}`).pipe(
      map((order) => this.toFrontendOrder(order))
    );
  }

  createReceivedOrder(order: ReceivedOrder): Observable<ReceivedOrder> {
    return this.http.post<ReceivedOrderApiModel>(this.baseUrl, this.toBackendOrder(order)).pipe(
      map((createdOrder) => this.toFrontendOrder(createdOrder))
    );
  }

  updateReceivedOrder(order: ReceivedOrder): Observable<ReceivedOrder> {
    return this.http.put<ReceivedOrderApiModel>(`${this.baseUrl}/update/${order.id}`, this.toBackendOrder(order)).pipe(
      map((updatedOrder) => this.toFrontendOrder(updatedOrder))
    );
  }

  updateReceivedOrderStatus(id: number, status: string): Observable<ReceivedOrder> {
    return this.http.put<ReceivedOrderApiModel>(`${this.baseUrl}/status/${id}`, { status }).pipe(
      map((updatedOrder) => this.toFrontendOrder(updatedOrder))
    );
  }

  deleteReceivedOrder(id: number): Observable<any> {
    return this.http.delete(this.baseUrl + '/delete/' + id, {
      responseType: 'text'
    });
  }

  private toFrontendOrder(order: ReceivedOrderApiModel): ReceivedOrder {
    return {
      id: Number(order.id ?? 0),
      orderNo: order.orderNo || order.orderNumber || '',
      supplierName: order.supplierName || '',
      warehouseId: this.normalizeNullableId(order.warehouseId),
      warehouseName: order.warehouseName || '',
      productId: this.normalizeNullableId(order.productId),
      productName: order.productName || '',
      quantity: Number(order.quantity ?? 0),
      receivedDate: order.receivedDate || '',
      status: order.status || 'Pending',
      totalAmount: Number(order.totalAmount ?? 0),
      createdAt: order.createdAt || '',
      updatedAt: order.updatedAt || '',
      stockApplied: !!order.stockApplied
    };
  }

  private toBackendOrder(order: ReceivedOrder): ReceivedOrderApiModel {
    return {
      id: order.id,
      orderNo: order.orderNo || '',
      supplierName: order.supplierName,
      warehouseId: order.warehouseId,
      warehouseName: order.warehouseName,
      productId: order.productId,
      productName: order.productName,
      quantity: Number(order.quantity ?? 0),
      receivedDate: order.receivedDate,
      status: order.status,
      totalAmount: Number(order.totalAmount ?? 0)
    };
  }

  private normalizeNullableId(value: number | string | null | undefined): number | null {
    const normalized = Number(value);
    return Number.isFinite(normalized) && normalized > 0 ? normalized : null;
  }
}
