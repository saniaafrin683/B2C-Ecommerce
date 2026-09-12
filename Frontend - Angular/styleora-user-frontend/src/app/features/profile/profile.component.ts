import { Component, OnInit } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';

import { AuthService, CustomerProfile } from '../../core/services/auth.service';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.css']
})
export class ProfileComponent implements OnInit {
  customer: CustomerProfile | null = null;
  errorMessage = '';
  isLoading = true;

  constructor(private readonly authService: AuthService) {}

  ngOnInit(): void {
    this.customer = this.authService.getCustomerSnapshot();

    this.authService.loadProfile().subscribe({
      next: (customer) => {
        this.customer = customer;
        this.isLoading = false;
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = error.error?.message || 'Unable to load your profile right now.';
        this.isLoading = false;
      }
    });
  }

  logout(): void {
    this.authService.logout();
  }
}
