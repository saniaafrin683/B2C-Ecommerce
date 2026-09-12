import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Order } from './order.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class OrdersService {
  private readonly apiUrl = `${environment.apiBaseUrl}/orders`;
  private readonly orderStatuses = ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  constructor(private http: HttpClient) {}

  createOrder(order: Order): Observable<Order> {
    return this.http.post<Order>(`${this.apiUrl}/create`, this.toApiPayload(order)).pipe(
      map((response) => this.normalizeOrder(response))
    );
  }

  getAllOrders(): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.apiUrl}/list`).pipe(
      map((orders) => (orders || []).map((item) => this.normalizeOrder(item)))
    );
  }

  getOrderById(id: number): Observable<Order> {
    return this.http.get<Order>(`${this.apiUrl}/${id}`).pipe(
      map((response) => this.normalizeOrder(response))
    );
  }

  updateOrder(id: number, order: Order): Observable<Order> {
    return this.http.put<Order>(`${this.apiUrl}/update/${id}`, this.toApiPayload(order)).pipe(
      map((response) => this.normalizeOrder(response))
    );
  }

  updateOrderStatus(id: number, status: string): Observable<Order> {
    return this.http.put<{ id: number; orderId: string; status?: string; orderStatus?: string; paymentStatus?: string }>(`${this.apiUrl}/status/${id}`, {
      status: this.normalizeStatus(status)
    }).pipe(
      map((response) => this.normalizeOrder({
        id: response?.id ?? id,
        orderId: response?.orderId,
        orderStatus: response?.orderStatus ?? response?.status,
        status: response?.status ?? response?.orderStatus,
        paymentStatus: response?.paymentStatus
      }))
    );
  }

  getAvailableOrderStatuses(): string[] {
    return [...this.orderStatuses];
  }

  deleteOrder(id: number): Observable<string> {
    return this.http.delete(`${this.apiUrl}/delete/${id}`, {
      responseType: 'text'
    });
  }

  private toApiPayload(order: Order): Order {
    return {
      ...order,
      createdAt: this.normalizeDate(order.createdAt || order.createdDate || ''),
      totalAmount: this.normalizeAmount(order.totalAmount ?? order.grandTotal ?? order.amount),
      grandTotal: this.normalizeAmount(order.totalAmount ?? order.grandTotal ?? order.amount),
      subtotal: this.normalizeAmount(order.subtotal),
      tax: this.normalizeAmount(order.tax),
      discount: this.normalizeAmount(order.discount),
      shippingCost: this.normalizeAmount(order.shippingCost),
      items: this.normalizeInteger(order.items ?? order.quantity),
      quantity: this.normalizeInteger(order.quantity ?? order.items),
      orderStatus: this.normalizeStatus(order.orderStatus || order.status || 'Pending'),
      status: this.normalizeStatus(order.orderStatus || order.status || 'Pending'),
      paymentStatus: (order.paymentStatus || 'Pending').trim(),
      customerName: (order.customerName || '').trim(),
      customerEmail: (order.customerEmail || order.email || '').trim(),
      customerPhone: (order.customerPhone || order.phone || '').trim(),
      shippingAddress: (order.shippingAddress || order.address || order.customer_address || '').trim(),
      billingAddress: (order.billingAddress || order.shippingAddress || order.address || order.customer_address || '').trim(),
      deliveryNumber: (order.deliveryNumber || '').trim(),
      trackingNumber: (order.trackingNumber || '').trim(),
      paymentMethod: (order.paymentMethod || '').trim(),
      priority: (order.priority || '').trim(),
      orderItems: (order.orderItems || []).map((item) => ({
        ...item,
        unitPrice: this.normalizeAmount(item.unitPrice),
        quantity: this.normalizeInteger(item.quantity),
        lineTotal: this.normalizeAmount(item.lineTotal ?? (item.unitPrice || 0) * (item.quantity || 0))
      }))
    };
  }

  private normalizeOrder(order: Order | null | undefined): Order {
    const totalAmount = this.normalizeAmount(order?.totalAmount ?? order?.grandTotal ?? order?.amount);
    const itemCount = this.normalizeInteger(order?.items ?? order?.quantity);
    const normalizedStatus = this.normalizeStatus(order?.orderStatus || order?.status || 'Pending');

    return {
      ...order,
      orderId: order?.orderId || (order?.id != null ? `#${order.id}` : ''),
      createdAt: this.normalizeDate(order?.createdAt || order?.createdDate || ''),
      createdDate: this.normalizeDate(order?.createdAt || order?.createdDate || ''),
      customerName: order?.customerName || 'N/A',
      customerEmail: order?.customerEmail || order?.email || '',
      customerPhone: order?.customerPhone || order?.phone || '',
      shippingAddress: order?.shippingAddress || order?.address || order?.customer_address || '',
      billingAddress: order?.billingAddress || order?.shippingAddress || order?.address || order?.customer_address || '',
      totalAmount,
      grandTotal: totalAmount,
      amount: totalAmount,
      subtotal: this.normalizeAmount(order?.subtotal),
      tax: this.normalizeAmount(order?.tax),
      discount: this.normalizeAmount(order?.discount),
      shippingCost: this.normalizeAmount(order?.shippingCost),
      items: itemCount,
      quantity: itemCount,
      paymentMethod: order?.paymentMethod || '',
      paymentStatus: order?.paymentStatus || 'Pending',
      orderStatus: normalizedStatus,
      status: normalizedStatus,
      priority: order?.priority || '',
      deliveryNumber: order?.deliveryNumber || '',
      trackingNumber: order?.trackingNumber || '',
      orderItems: (order?.orderItems || []).map((item) => ({
        ...item,
        unitPrice: this.normalizeAmount(item?.unitPrice),
        quantity: this.normalizeInteger(item?.quantity),
        lineTotal: this.normalizeAmount(item?.lineTotal ?? (item?.unitPrice || 0) * (item?.quantity || 0))
      }))
    };
  }

  private normalizeDate(value: string | undefined): string {
    if (!value) {
      return '';
    }

    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      return value;
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return value;
    }

    return parsed.toISOString().split('T')[0];
  }

  private normalizeAmount(value: number | string | null | undefined): number {
    const amount = Number(value ?? 0);
    return Number.isFinite(amount) ? amount : 0;
  }

  private normalizeInteger(value: number | string | null | undefined): number {
    const count = Number(value ?? 0);
    return Number.isFinite(count) ? Math.max(0, Math.round(count)) : 0;
  }

  private normalizeStatus(value: string | null | undefined): string {
    const rawStatus = (value || '').trim().toLowerCase();

    if (!rawStatus || rawStatus === 'pending review') {
      return 'Pending';
    }

    if (rawStatus === 'in progress') {
      return 'Processing';
    }

    const matchedStatus = this.orderStatuses.find((status) => status.toLowerCase() === rawStatus);
    return matchedStatus || 'Pending';
  }
}
