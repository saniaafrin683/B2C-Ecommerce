import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Customer } from './customer.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private readonly baseUrl = `${environment.apiBaseUrl}/customers`;

  constructor(private http: HttpClient) {}

  getCustomers(): Observable<Customer[]> {
    return this.http.get<Customer[]>(`${this.baseUrl}/list`).pipe(
      catchError((error) => this.handleError('load customers', error))
    );
  }

  getDeletedCustomers(): Observable<Customer[]> {
    return this.http.get<Customer[]>(`${this.baseUrl}/deleted`).pipe(
      catchError((error) => this.handleError('load deleted customers', error))
    );
  }

  getCustomerById(id: number): Observable<Customer> {
    return this.http.get<Customer>(`${this.baseUrl}/${id}`).pipe(
      catchError((error) => this.handleError(`load customer ${id}`, error))
    );
  }

  createCustomer(customer: Customer): Observable<Customer> {
    return this.http.post<Customer>(`${this.baseUrl}/create`, customer).pipe(
      catchError((error) => this.handleError('create customer', error))
    );
  }

  updateCustomer(id: number, customer: Customer): Observable<Customer> {
    return this.http.put<Customer>(`${this.baseUrl}/update/${id}`, customer).pipe(
      catchError((error) => this.handleError(`update customer ${id}`, error))
    );
  }

  deleteCustomer(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`).pipe(
      catchError((error) => this.handleError(`delete customer ${id}`, error))
    );
  }

  restoreCustomer(id: number): Observable<void> {
    return this.http.put<void>(`${this.baseUrl}/restore/${id}`, {}).pipe(
      catchError((error) => this.handleError(`restore customer ${id}`, error))
    );
  }

  permanentlyDeleteCustomer(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/permanent/${id}`).pipe(
      catchError((error) => this.handleError(`permanently delete customer ${id}`, error))
    );
  }

  private handleError(action: string, error: HttpErrorResponse): Observable<never> {
    console.error(`CustomerService failed to ${action}`, error);
    return throwError(() => error);
  }
}
