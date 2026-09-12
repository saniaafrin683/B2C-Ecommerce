import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Review } from './review.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ReviewService {
  private readonly baseUrl = `${environment.apiBaseUrl}/reviews`;

  constructor(private http: HttpClient) {}

  getReviews(): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/list`);
  }

  getApprovedReviews(limit = 6): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/approved?limit=${limit}`);
  }

  getApprovedReviewsByProduct(productId: number, limit = 6): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/product/${productId}/approved?limit=${limit}`);
  }

  getReviewById(id: number): Observable<Review> {
    return this.http.get<Review>(`${this.baseUrl}/${id}`);
  }

  createReview(review: Review): Observable<Review> {
    return this.http.post<Review>(`${this.baseUrl}/create`, review);
  }

  updateReview(id: number, review: Review): Observable<Review> {
    return this.http.put<Review>(`${this.baseUrl}/update/${id}`, review);
  }

  approveReview(id: number): Observable<Review> {
    return this.http.put<Review>(`${this.baseUrl}/approve/${id}`, {});
  }

  rejectReview(id: number): Observable<Review> {
    return this.http.put<Review>(`${this.baseUrl}/reject/${id}`, {});
  }

  deleteReview(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }
}
