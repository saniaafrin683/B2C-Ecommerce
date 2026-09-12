import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';

export interface CreateOrderItemPayload {
  productId: number;
  productName: string;
  productImage: string;
  size: string;
  color: string;
  originalUnitPrice?: number;
  discountedUnitPrice?: number;
  productDiscountRate?: number;
  productDiscountAmount?: number;
  originalLineTotal?: number;
  productDiscountLineTotal?: number;
  unitPrice: number;
  quantity: number;
  reservedQuantity?: number;
  lineTotal: number;
}

export interface CreateOrderPayload {
  id?: number;
  orderId: string;
  createdAt: string;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  shippingAddress: string;
  billingAddress: string;
  priority: string;
  subtotal: number;
  regularSubtotal?: number;
  productDiscountTotal?: number;
  subtotalAfterProductDiscount?: number;
  tax: number;
  discount: number;
  couponDiscount?: number;
  shippingCost: number;
  couponCode?: string;
  totalAmount: number;
  paymentMethod: string;
  paymentStatus: string;

  paymentSenderNumber?: string;
  paymentTransactionId?: string;

  deliveryNumber?: string;
  trackingNumber?: string;

  orderStatus: string;
  orderItems: CreateOrderItemPayload[];
}

export interface OrderSummary {
  id: number;
  orderId: string;
  customerName: string;
  customerEmail?: string;
  customerPhone?: string;
  shippingAddress?: string;
  billingAddress?: string;
  paymentMethod?: string;
  paymentStatus?: string;
  paymentSenderNumber?: string;
  paymentTransactionId?: string;
  trackingNumber?: string;
  courierName?: string;
  shipmentStatus?: string;
  shippedDate?: string;
  estimatedDeliveryDate?: string;
  deliveredDate?: string;
  couponCode?: string;
  discount?: number;
  couponDiscount?: number;
  regularSubtotal?: number;
  productDiscountTotal?: number;
  subtotalAfterProductDiscount?: number;
  totalAmount: number;
  orderStatus: string;
  createdAt: string;
}

export interface OrderDetails extends OrderSummary {
  tax?: number;
  shippingCost?: number;
  subtotal?: number;
  orderItems?: CreateOrderItemPayload[];
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private readonly apiBaseUrl = environment.apiBaseUrl || 'http://localhost:8080';
  private readonly createOrderUrl = `${this.apiBaseUrl}/orders/create`;
  private readonly listOrdersUrl = `${this.apiBaseUrl}/orders/my`;

  constructor(private readonly http: HttpClient) {}

  createOrder(orderData: CreateOrderPayload): Observable<OrderDetails> {
    return this.http.post<OrderDetails>(this.createOrderUrl, orderData);
  }

  getOrders(): Observable<OrderSummary[]> {
    return this.http.get<OrderSummary[]>(this.listOrdersUrl);
  }

  getOrderById(id: number): Observable<OrderDetails> {
    return this.http.get<OrderDetails>(`${this.apiBaseUrl}/orders/my/${id}`);
  }

  getOrderByReference(orderId: string): Observable<OrderDetails> {
    return this.http.get<OrderDetails>(
      `${this.apiBaseUrl}/orders/my/reference/${encodeURIComponent(orderId)}`
    );
  }
}