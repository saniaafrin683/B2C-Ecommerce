import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Payment } from './payment.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class PaymentService {
  private readonly baseUrl = `${environment.apiBaseUrl || 'http://localhost:8080'}/payments`;

  constructor(private http: HttpClient) {}

  createPayment(payment: Payment): Observable<Payment> {
    return this.http.post<Payment>(`${this.baseUrl}/create`, payment).pipe(catchError((error) => this.handleError(error)));
  }

  getPayments(): Observable<Payment[]> {
    return this.http.get<Payment[]>(`${this.baseUrl}/list`).pipe(catchError((error) => this.handleError(error)));
  }

  getPaymentById(id: number): Observable<Payment> {
    return this.http.get<Payment>(`${this.baseUrl}/${id}`).pipe(catchError((error) => this.handleError(error)));
  }

  getPaymentsByInvoiceId(invoiceId: number): Observable<Payment[]> {
    return this.http.get<Payment[]>(`${this.baseUrl}/by-invoice/${invoiceId}`).pipe(catchError((error) => this.handleError(error)));
  }

  getPaymentsByOrderId(orderId: number): Observable<Payment[]> {
    return this.http.get<Payment[]>(`${this.baseUrl}/by-order/${orderId}`).pipe(catchError((error) => this.handleError(error)));
  }

  updatePayment(id: number, payment: Payment): Observable<Payment> {
    return this.http.put<Payment>(`${this.baseUrl}/update/${id}`, payment).pipe(catchError((error) => this.handleError(error)));
  }

  deletePayment(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`).pipe(catchError((error) => this.handleError(error)));
  }

  private handleError(error: HttpErrorResponse) {
    const message =
      typeof error.error === 'string'
        ? error.error
        : error.error?.message || error.message || 'Payment request failed.';

    return throwError(() => new Error(message));
  }
}
