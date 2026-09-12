import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable, tap } from 'rxjs';

import { environment } from '../../../environments/environment';

export interface CustomerProfile {
  id: number;
  customerCode: string;
  fullName: string;
  email: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  status?: string;
  registeredAt?: string;
}

export interface CustomerAuthResponse {
  success: boolean;
  message: string;
  token: string;
  role: string;
  customer: CustomerProfile;
}

interface CustomerAuthState {
  token: string;
  customer: CustomerProfile;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly storageKey = 'styleora_customer_auth';
  private readonly baseUrl = environment.apiBaseUrl || 'http://localhost:8080';
  private readonly authStateSubject = new BehaviorSubject<CustomerAuthState | null>(this.readAuthState());

  readonly authState$ = this.authStateSubject.asObservable();

  constructor(
    private readonly http: HttpClient,
    private readonly router: Router
  ) {}

  login(payload: { email: string; password: string }): Observable<CustomerAuthResponse> {
    return this.http.post<CustomerAuthResponse>(`${this.baseUrl}/customers/login`, payload).pipe(
      tap((response) => this.persistAuth(response))
    );
  }

  register(payload: {
    fullName: string;
    email: string;
    password: string;
    phone?: string;
    address?: string;
    city?: string;
    country?: string;
  }): Observable<CustomerAuthResponse> {
    return this.http.post<CustomerAuthResponse>(`${this.baseUrl}/customers/register`, payload).pipe(
      tap((response) => this.persistAuth(response))
    );
  }

  loadProfile(): Observable<CustomerProfile> {
    return this.http.get<CustomerProfile>(`${this.baseUrl}/customers/profile`).pipe(
      tap((customer) => {
        const currentState = this.authStateSubject.value;
        if (!currentState?.token) {
          return;
        }

        this.writeAuthState({
          token: currentState.token,
          customer
        });
      })
    );
  }

  isAuthenticated(): boolean {
    return !!this.authStateSubject.value?.token;
  }

  getToken(): string {
    return this.authStateSubject.value?.token || '';
  }

  getCustomerSnapshot(): CustomerProfile | null {
    return this.authStateSubject.value?.customer || null;
  }

  logout(navigateToLogin = true): void {
    sessionStorage.removeItem(this.storageKey);
    this.authStateSubject.next(null);

    if (navigateToLogin) {
      void this.router.navigate(['/login']);
    }
  }

  private persistAuth(response: CustomerAuthResponse): void {
    if (!response?.token || !response?.customer) {
      return;
    }

    this.writeAuthState({
      token: response.token,
      customer: response.customer
    });
  }

  private writeAuthState(state: CustomerAuthState): void {
    sessionStorage.setItem(this.storageKey, JSON.stringify(state));
    this.authStateSubject.next(state);
  }

  private readAuthState(): CustomerAuthState | null {
    const rawValue = sessionStorage.getItem(this.storageKey);
    if (!rawValue) {
      return null;
    }

    try {
      const parsedValue = JSON.parse(rawValue) as Partial<CustomerAuthState> | null;
      if (!parsedValue?.token || !parsedValue?.customer?.email) {
        sessionStorage.removeItem(this.storageKey);
        return null;
      }

      return {
        token: parsedValue.token,
        customer: parsedValue.customer as CustomerProfile
      };
    } catch {
      sessionStorage.removeItem(this.storageKey);
      return null;
    }
  }
}
