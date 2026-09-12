import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { finalize } from 'rxjs/operators';
import { AuthService } from '../../../core/services/auth.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  email = '';
  password = '';
  submitting = false;
  errorMessage = '';

  constructor(
    private authService: AuthService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private router: Router
  ) {
    if (this.authService.isLoggedIn()) {
      this.router.navigate(['/dashboard']);
    }
  }

  onSubmit(): void {
    this.errorMessage = '';
    this.submitting = true;
    this.loadingService.show();

    this.authService.login(this.email.trim(), this.password).pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (response) => {
        if (response?.success) {
          this.notificationService.showSuccess('Login successful.');
          this.router.navigate(['/dashboard']);
          return;
        }

        this.errorMessage = response?.message || 'Login failed.';
        this.password = '';
        this.notificationService.showError(this.errorMessage);
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = this.getLoginErrorMessage(error);
        this.password = '';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  private getLoginErrorMessage(error: HttpErrorResponse): string {
    const backendMessage = error?.error?.message;
    if (backendMessage) {
      return backendMessage;
    }

    if (error.status === 0) {
      return 'Unable to reach the server. Please check whether the backend is running.';
    }

    if (error.status >= 500) {
      return 'The server could not complete the login request. Please try again.';
    }

    if (error.status === 401 || error.status === 403) {
      return 'Invalid email or password.';
    }

    return 'Login failed. Please check your credentials and try again.';
  }
}
