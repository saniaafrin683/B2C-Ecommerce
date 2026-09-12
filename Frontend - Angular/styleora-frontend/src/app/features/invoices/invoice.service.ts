import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Invoice } from './invoice.model';
import { Order } from '../orders/order.model';
import { SettingsService } from '../../core/services/settings.service';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class InvoiceService {
  private readonly baseUrl = `${environment.apiBaseUrl}/invoices`;

  constructor(
    private http: HttpClient,
    private settingsService: SettingsService
  ) {}

  createInvoice(invoice: Invoice): Observable<Invoice> {
    return this.http.post<Invoice>(`${this.baseUrl}/create`, invoice);
  }

  getInvoices(): Observable<Invoice[]> {
    return this.http.get<Invoice[]>(`${this.baseUrl}/list`);
  }

  getInvoiceById(id: number): Observable<Invoice> {
    return this.http.get<Invoice>(`${this.baseUrl}/${id}`);
  }

  getInvoicesByOrderId(orderId: number): Observable<Invoice[]> {
    return this.http.get<Invoice[]>(`${this.baseUrl}/by-order/${orderId}`);
  }

  updateInvoice(id: number, invoice: Invoice): Observable<Invoice> {
    return this.http.put<Invoice>(`${this.baseUrl}/update/${id}`, invoice);
  }

  deleteInvoice(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  buildInvoiceFromOrder(order: Order, orderDatabaseId: number): Invoice {
    const issueDate = order.createdAt || this.getTodayDate();
    return {
      id: 0,
      invoiceNumber: this.generateInvoiceNumber(order.orderId || `${orderDatabaseId}`),
      orderId: orderDatabaseId,
      orderReference: order.orderId || `${orderDatabaseId}`,
      customerName: order.customerName || '',
      customerEmail: order.customerEmail || '',
      customerPhone: order.customerPhone || '',
      billingAddress: order.billingAddress || order.shippingAddress || '',
      subtotal: Number(order.subtotal ?? order.totalAmount ?? 0),
      regularSubtotal: Number(order.regularSubtotal ?? order.subtotal ?? order.totalAmount ?? 0),
      productDiscountTotal: Number(order.productDiscountTotal ?? 0),
      subtotalAfterProductDiscount: Number(order.subtotalAfterProductDiscount ?? order.subtotal ?? order.totalAmount ?? 0),
      tax: Number(order.tax ?? 0),
      discount: Number(order.discount ?? 0),
      couponDiscount: Number(order.couponDiscount ?? order.discount ?? 0),
      couponCode: order.couponCode || '',
      shippingCost: Number(order.shippingCost ?? 0),
      totalAmount: Number(order.totalAmount ?? 0),
      paymentStatus: order.paymentStatus || 'Pending',
      paymentMethod: order.paymentMethod || 'Not Set',
      issueDate,
      dueDate: issueDate,
      notes: `Auto-generated from order ${order.orderId || orderDatabaseId}`
    };
  }

  private generateInvoiceNumber(orderIdentifier: string): string {
    const safePart = (orderIdentifier || '').replace(/[^A-Za-z0-9]/g, '').slice(-8);
    return `${this.settingsService.getInvoicePrefix()}-${safePart || Date.now().toString().slice(-8)}`;
  }

  private getTodayDate(): string {
    return new Date().toISOString().split('T')[0];
  }
}
