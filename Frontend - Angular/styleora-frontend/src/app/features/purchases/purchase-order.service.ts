import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { PurchaseOrder, PurchaseOrderLineItem } from './purchase-order.model';

interface PurchaseOrderApiModel {
  id?: number;
  purchaseOrderId?: string;
  supplierName?: string;
  supplierEmail?: string;
  supplierPhone?: string;
  supplierAddress?: string;
  orderDate?: string;
  expectedDeliveryDate?: string;
  orderStatus?: string;
  paymentStatus?: string;
  paymentMethod?: string;
  items?: string | PurchaseOrderLineItem[];
  subtotal?: number;
  discount?: number;
  tax?: number;
  shippingCost?: number;
  totalAmount?: number;
  paidAmount?: number;
  dueAmount?: number;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class PurchaseOrderService {
  private readonly baseUrl = 'http://localhost:8080/purchase-orders';

  constructor(private http: HttpClient) {}

  getPurchaseOrders(): Observable<PurchaseOrder[]> {
    return this.http
      .get<PurchaseOrderApiModel[]>(`${this.baseUrl}/list`)
      .pipe(map((orders) => (orders || []).map((order) => this.toFrontendOrder(order))));
  }

  getPurchaseOrderById(id: number): Observable<PurchaseOrder> {
    return this.http
      .get<PurchaseOrderApiModel>(`${this.baseUrl}/${id}`)
      .pipe(map((order) => this.toFrontendOrder(order)));
  }

  createPurchaseOrder(order: PurchaseOrder): Observable<PurchaseOrder> {
    return this.http
      .post<PurchaseOrderApiModel>(`${this.baseUrl}/create`, this.toBackendOrder(order))
      .pipe(map((createdOrder) => this.toFrontendOrder(createdOrder)));
  }

  updatePurchaseOrder(id: number, order: PurchaseOrder): Observable<PurchaseOrder> {
    return this.http
      .put<PurchaseOrderApiModel>(`${this.baseUrl}/update/${id}`, this.toBackendOrder(order))
      .pipe(map((updatedOrder) => this.toFrontendOrder(updatedOrder)));
  }

  deletePurchaseOrder(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  private toFrontendOrder(order: PurchaseOrderApiModel): PurchaseOrder {
    return {
      id: Number(order.id ?? 0),
      purchaseOrderId: order.purchaseOrderId || '',
      supplierName: order.supplierName || '',
      supplierEmail: order.supplierEmail || '',
      supplierPhone: order.supplierPhone || '',
      supplierAddress: order.supplierAddress || '',
      orderDate: order.orderDate || '',
      expectedDeliveryDate: order.expectedDeliveryDate || '',
      orderStatus: order.orderStatus || 'Pending',
      paymentStatus: order.paymentStatus || 'Pending',
      paymentMethod: order.paymentMethod || '',
      items: this.parseItems(order.items),
      subtotal: Number(order.subtotal ?? 0),
      discount: Number(order.discount ?? 0),
      tax: Number(order.tax ?? 0),
      shippingCost: Number(order.shippingCost ?? 0),
      totalAmount: Number(order.totalAmount ?? 0),
      paidAmount: Number(order.paidAmount ?? 0),
      dueAmount: Number(order.dueAmount ?? 0),
      notes: order.notes || ''
    };
  }

  private toBackendOrder(order: PurchaseOrder): PurchaseOrderApiModel {
    return {
      id: order.id,
      purchaseOrderId: order.purchaseOrderId,
      supplierName: order.supplierName,
      supplierEmail: order.supplierEmail || '',
      supplierPhone: order.supplierPhone || '',
      supplierAddress: order.supplierAddress || '',
      orderDate: order.orderDate,
      expectedDeliveryDate: order.expectedDeliveryDate || null as unknown as string,
      orderStatus: order.orderStatus,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod || '',
      items: JSON.stringify(order.items || []),
      subtotal: Number(order.subtotal ?? 0),
      discount: Number(order.discount ?? 0),
      tax: Number(order.tax ?? 0),
      shippingCost: Number(order.shippingCost ?? 0),
      totalAmount: Number(order.totalAmount ?? 0),
      paidAmount: Number(order.paidAmount ?? 0),
      dueAmount: Number(order.dueAmount ?? 0),
      notes: order.notes || ''
    };
  }

  private parseItems(items: string | PurchaseOrderLineItem[] | undefined): PurchaseOrderLineItem[] {
    if (!items) {
      return [];
    }

    if (Array.isArray(items)) {
      return items.map((item) => ({ ...item }));
    }

    try {
      const parsedItems = JSON.parse(items);
      return Array.isArray(parsedItems)
        ? parsedItems.map((item) => ({
            product: item?.product || '',
            sku: item?.sku || '',
            quantity: Number(item?.quantity ?? 0),
            unitCost: Number(item?.unitCost ?? 0),
            discount: Number(item?.discount ?? 0),
            tax: Number(item?.tax ?? 0),
            total: Number(item?.total ?? 0)
          }))
        : [];
    } catch {
      return [];
    }
  }
}
