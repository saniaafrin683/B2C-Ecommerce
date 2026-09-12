import { Component } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { Router } from '@angular/router';

import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.css']
})
export class AuthComponent {
  mode = 'login';
  isSubmitting = false;
  errorMessage = '';
  successMessage = '';

  formData = {
    fullName: '',
    email: '',
    password: '',
    phone: '',
    address: '',
    city: '',
    country: ''
  };

  constructor(
    private route: ActivatedRoute,
    private readonly router: Router,
    private readonly authService: AuthService
  ) {
    const parentData = this.route.parent?.snapshot.data;
    this.mode = parentData?.['authMode'] || 'login';
  }

  get title() {
    return this.mode === 'register' ? 'Create an account' : 'Login to Styleora';
  }

  get submitLabel() {
    return this.mode === 'register' ? 'Register' : 'Login';
  }

  submit(): void {
    this.errorMessage = '';
    this.successMessage = '';
    this.isSubmitting = true;

    const request$ = this.mode === 'register'
      ? this.authService.register({
          fullName: this.formData.fullName.trim(),
          email: this.formData.email.trim(),
          password: this.formData.password,
          phone: this.formData.phone.trim(),
          address: this.formData.address.trim(),
          city: this.formData.city.trim(),
          country: this.formData.country.trim()
        })
      : this.authService.login({
          email: this.formData.email.trim(),
          password: this.formData.password
        });

    request$.subscribe({
      next: (response) => {
        this.successMessage = response.message || `${this.submitLabel} successful.`;
        this.isSubmitting = false;
        void this.router.navigate(['/profile']);
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = this.resolveErrorMessage(error);
        this.isSubmitting = false;
      }
    });
  }

  private resolveErrorMessage(error: HttpErrorResponse): string {
    if (error.error?.validationErrors) {
      const messages = Object.values(error.error.validationErrors) as string[];
      if (messages.length) {
        return messages[0];
      }
    }

    return error.error?.message || 'Unable to complete the request right now.';
  }
}
