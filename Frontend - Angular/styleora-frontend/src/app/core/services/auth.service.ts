import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { Router } from '@angular/router';
import { environment } from '../../../environments/environment';
import { AdminRole, normalizeAdminRole } from '../auth/admin-role.model';

interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  email: string | null;
  adminEmail?: string | null;
  token?: string | null;
  role?: string | null;
}

interface AuthState {
  email: string;
  token: string;
  role: AdminRole;
  loggedInAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly apiUrl = `${environment.apiBaseUrl}/auth/login`;
  private readonly storageKey = 'styleora_admin_auth';

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  login(email: string, password: string): Observable<LoginResponse> {
    const payload: LoginRequest = { email, password };

    return this.http.post<LoginResponse>(this.apiUrl, payload).pipe(
      map((response) => {
        if (response?.success && response?.token) {
          const resolvedEmail = response.adminEmail || response.email || email;
          const authState: AuthState = {
            email: resolvedEmail,
            token: response.token,
            role: normalizeAdminRole(response.role),
            loggedInAt: new Date().toISOString()
          };

          localStorage.setItem(this.storageKey, JSON.stringify(authState));
        }

        return response;
      })
    );
  }

  isLoggedIn(): boolean {
    return this.getAuthState() !== null;
  }

  logout(): void {
    localStorage.removeItem(this.storageKey);
    this.router.navigate(['/login']);
  }

  handleForbiddenAccess(): void {
    if (!this.isLoggedIn()) {
      this.router.navigate(['/login']);
      return;
    }

    if (this.router.url !== '/access-denied') {
      this.router.navigate(['/access-denied'], {
        queryParams: {
          from: this.router.url || '/dashboard'
        }
      });
    }
  }

  navigateToDefaultDashboard(): void {
    this.router.navigate(['/dashboard']);
  }

  getAdminEmail(): string {
    return this.getAuthState()?.email || 'Admin';
  }

  getToken(): string {
    return this.getAuthState()?.token || '';
  }

  getRole(): AdminRole {
    return this.getAuthState()?.role || 'ADMIN';
  }

  hasRole(role: AdminRole): boolean {
    return this.isLoggedIn() && this.getRole() === role;
  }

  hasAnyRole(roles: AdminRole[]): boolean {
    return this.isLoggedIn() && roles.includes(this.getRole());
  }

  private getAuthState(): AuthState | null {
    const rawValue = localStorage.getItem(this.storageKey);
    if (!rawValue) {
      return null;
    }

    try {
      const parsedValue = JSON.parse(rawValue) as Partial<AuthState> | null;
      if (!parsedValue?.email || !parsedValue?.token || !parsedValue?.loggedInAt) {
        localStorage.removeItem(this.storageKey);
        return null;
      }

      return {
        email: parsedValue.email,
        token: parsedValue.token,
        role: normalizeAdminRole(parsedValue.role),
        loggedInAt: parsedValue.loggedInAt
      };
    } catch {
      localStorage.removeItem(this.storageKey);
      return null;
    }
  }
}
