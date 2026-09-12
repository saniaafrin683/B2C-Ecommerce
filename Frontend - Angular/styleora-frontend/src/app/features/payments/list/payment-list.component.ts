import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Payment } from '../payment.model';
import { PaymentService } from '../payment.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-payment-list',
  templateUrl: './payment-list.component.html',
  styleUrls: ['./payment-list.component.css']
})
export class PaymentListComponent implements OnInit {
  payments: Payment[] = [];
  paginatedPayments: Payment[] = [];
  loading = false;
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  constructor(
    private paymentService: PaymentService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadPayments();
  }

  get totalPayments(): number {
    return this.payments.length;
  }

  get paidPayments(): number {
    return this.payments.filter((payment) => this.isPaidStatus(payment.paymentStatus)).length;
  }

  get pendingPayments(): number {
    return this.payments.filter((payment) => this.isPendingStatus(payment.paymentStatus)).length;
  }

  get failedPayments(): number {
    return this.payments.filter((payment) => this.isFailedStatus(payment.paymentStatus)).length;
  }

  loadPayments(): void {
    this.loading = true;
    this.errorMessage = '';

    this.paymentService.getPayments().subscribe({
      next: (payments) => {
        this.payments = payments || [];
        this.currentPage = 1;
        this.updatePaginatedPayments();
        this.loading = false;
      },
      error: (error: Error) => {
        this.loading = false;
        this.errorMessage = error.message || 'Failed to load payments.';
      }
    });
  }

  onCreate(): void {
    this.router.navigate(['/payments/create']);
  }

  onView(payment: Payment): void {
    this.router.navigate(['/payments/details', payment.id]);
  }

  onEdit(payment: Payment): void {
    this.router.navigate(['/payments/edit', payment.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this transaction?');
    if (!confirmed) {
      return;
    }

    this.paymentService.deletePayment(id).subscribe({
      next: () => this.loadPayments(),
      error: (error: Error) => {
        this.errorMessage = error.message || 'Failed to delete payment.';
      }
    });
  }

  getStatusClass(status: string): string {
    if (this.isPaidStatus(status)) {
      return 'pill-success';
    }
    if (this.isFailedStatus(status)) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getInitials(name: string): string {
    if (!name) {
      return 'NA';
    }

    return name
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part.charAt(0).toUpperCase())
      .join('');
  }

  getPaymentMethodClass(method: string): string {
    const normalized = (method || '').toLowerCase();

    if (normalized.includes('visa') || normalized.includes('mastercard') || normalized.includes('card')) {
      return 'method-card';
    }

    if (normalized.includes('paypal')) {
      return 'method-paypal';
    }

    if (normalized.includes('cash')) {
      return 'method-cash';
    }

    if (normalized.includes('bank')) {
      return 'method-bank';
    }

    return 'method-default';
  }

  private isPaidStatus(status: string): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('paid') || normalized.includes('completed') || normalized.includes('success');
  }

  private isPendingStatus(status: string): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('pending') || normalized.includes('processing');
  }

  private isFailedStatus(status: string): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('failed') || normalized.includes('cancel') || normalized.includes('declined');
  }

  get totalPages(): number {
    return getTotalPages(this.payments.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedPayments();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedPayments(): void {
    this.paginatedPayments = getPaginatedItems(this.payments, this.currentPage, this.pageSize);
  }
}
