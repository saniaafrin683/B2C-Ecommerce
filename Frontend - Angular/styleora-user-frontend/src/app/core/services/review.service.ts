import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';

export interface ReviewRecord {
  id: number;
  reviewCode?: string;
  orderId?: number;
  productId?: number;
  productName?: string;
  customerId?: number;
  customerName?: string;
  customerEmail?: string;
  rating: number;
  reviewTitle?: string;
  reviewMessage?: string;
  reviewStatus?: string;
  reviewDate?: string;
  replyMessage?: string;
}

export interface ReviewSubmitPayload {
  orderId: number;
  productId: number;
  rating: number;
  comment: string;
}

@Injectable({
  providedIn: 'root'
})
export class ReviewService {
  private readonly baseUrl = `${environment.apiBaseUrl}/reviews`;

  constructor(private readonly http: HttpClient) {}

  getApprovedReviews(limit = 6): Observable<ReviewRecord[]> {
    return this.http.get<ReviewRecord[]>(`${this.baseUrl}/approved?limit=${limit}`);
  }

  getApprovedReviewsByProduct(productId: number, limit = 6): Observable<ReviewRecord[]> {
    return this.http.get<ReviewRecord[]>(`${this.baseUrl}/product/${productId}/approved?limit=${limit}`);
  }

  getMyReviewsForOrder(orderId: number): Observable<ReviewRecord[]> {
    return this.http.get<ReviewRecord[]>(`${this.baseUrl}/my/order/${orderId}`);
  }

  getMyReviews(): Observable<ReviewRecord[]> {
    return this.http.get<ReviewRecord[]>(`${this.baseUrl}/my`);
  }

  submitReview(payload: ReviewSubmitPayload): Observable<ReviewRecord> {
    return this.http.post<ReviewRecord>(`${this.baseUrl}/submit`, payload);
  }
}
