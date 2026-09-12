import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Invoice } from '../invoice.model';
import { InvoiceService } from '../invoice.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-invoice-list',
  templateUrl: './invoice-list.component.html',
  styleUrls: ['./invoice-list.component.css']
})
export class InvoiceListComponent implements OnInit {
  invoices: Invoice[] = [];
  paginatedInvoices: Invoice[] = [];
  loading = false;
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  constructor(
    private invoiceService: InvoiceService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadInvoices();
  }

  get totalInvoices(): number {
    return this.invoices.length;
  }

  get pendingInvoices(): number {
    return this.invoices.filter((invoice) => this.isPendingStatus(invoice.paymentStatus)).length;
  }

  get paidInvoices(): number {
    return this.invoices.filter((invoice) => this.isPaidStatus(invoice.paymentStatus)).length;
  }

  get cancelledInvoices(): number {
    return this.invoices.filter((invoice) => this.isInactiveStatus(invoice.paymentStatus)).length;
  }

  loadInvoices(): void {
    this.loading = true;
    this.errorMessage = '';

    this.invoiceService.getInvoices().subscribe({
      next: (invoices) => {
        this.invoices = invoices || [];
        this.currentPage = 1;
        this.updatePaginatedInvoices();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load invoices.';
      }
    });
  }

  onView(invoice: Invoice): void {
    this.router.navigate(['/invoices/details', invoice.id]);
  }

  onPrint(invoice: Invoice): void {
    this.router.navigate(['/invoices/print', invoice.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this invoice?');
    if (!confirmed) {
      return;
    }

    this.invoiceService.deleteInvoice(id).subscribe({
      next: () => this.loadInvoices(),
      error: () => {
        this.errorMessage = 'Failed to delete invoice.';
      }
    });
  }

  getStatusClass(status: string): string {
    if (this.isPaidStatus(status)) {
      return 'pill-success';
    }
    if (this.isInactiveStatus(status)) {
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
    return normalized.includes('paid') || normalized.includes('completed');
  }

  private isPendingStatus(status: string): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('pending');
  }

  private isInactiveStatus(status: string): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('cancel') || normalized.includes('failed') || normalized.includes('inactive');
  }

  get totalPages(): number {
    return getTotalPages(this.invoices.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedInvoices();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedInvoices(): void {
    this.paginatedInvoices = getPaginatedItems(this.invoices, this.currentPage, this.pageSize);
  }
}
