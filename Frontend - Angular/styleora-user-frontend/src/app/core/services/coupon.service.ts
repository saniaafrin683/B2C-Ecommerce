import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';

export interface ApplyCouponPayload {
  couponCode: string;
  subtotal: number;
  orderItems?: Array<{
    productId: number;
    quantity: number;
  }>;
}

export interface AppliedCoupon {
  couponCode: string;
  discountType: string;
  discountAmount: number;
  subtotal: number;
  regularSubtotal: number;
  productDiscountTotal: number;
  subtotalAfterProductDiscount: number;
  couponDiscount: number;
  finalTotal: number;
  message: string;
}

@Injectable({
  providedIn: 'root'
})
export class CouponService {
  private readonly apiBaseUrl = environment.apiBaseUrl || 'http://localhost:8080';

  constructor(private readonly http: HttpClient) {}

  applyCoupon(payload: ApplyCouponPayload): Observable<AppliedCoupon> {
    return this.http.post<AppliedCoupon>(`${this.apiBaseUrl}/coupons/apply`, payload);
  }
}
