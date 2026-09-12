import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Customer } from '../customer.model';
import { CustomerService } from '../customer.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-restore-customers',
  templateUrl: './restore-customers.component.html',
  styleUrls: ['./restore-customers.component.css']
})
export class RestoreCustomersComponent implements OnInit {
  customers: Customer[] = [];
  paginatedCustomers: Customer[] = [];
  loading = false;
  restoringId: number | null = null;
  deletingId: number | null = null;
  successMessage = '';
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  constructor(
    private customerService: CustomerService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadDeletedCustomers();
  }

  loadDeletedCustomers(): void {
    this.loading = true;
    this.successMessage = '';
    this.errorMessage = '';

    this.customerService.getDeletedCustomers().subscribe({
      next: (customers) => {
        this.customers = customers || [];
        this.currentPage = 1;
        this.updatePaginatedCustomers();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load deleted customers.';
      }
    });
  }

  onView(customer: Customer): void {
    this.router.navigate(['/customers/details', customer.id]);
  }

  onRestore(customer: Customer): void {
    const customerId = customer.id;
    if (!customerId) {
      return;
    }

    this.restoringId = customerId;
    this.successMessage = '';
    this.errorMessage = '';

    this.customerService.restoreCustomer(customerId).subscribe({
      next: () => {
        this.customers = this.customers.filter((item) => item.id !== customerId);
        this.currentPage = clampPage(this.currentPage, this.totalPages);
        this.updatePaginatedCustomers();
        this.restoringId = null;
        this.successMessage = 'Customer restored successfully.';
      },
      error: (error) => {
        this.restoringId = null;
        this.errorMessage = error?.error?.message || 'Failed to restore customer.';
      }
    });
  }

  onPermanentDelete(customer: Customer): void {
    const customerId = customer.id;
    if (!customerId) {
      return;
    }

    const confirmed = confirm(`Permanently delete ${customer.fullName || 'this customer'}? This cannot be undone.`);
    if (!confirmed) {
      return;
    }

    this.deletingId = customerId;
    this.successMessage = '';
    this.errorMessage = '';

    this.customerService.permanentlyDeleteCustomer(customerId).subscribe({
      next: () => {
        this.customers = this.customers.filter((item) => item.id !== customerId);
        this.currentPage = clampPage(this.currentPage, this.totalPages);
        this.updatePaginatedCustomers();
        this.deletingId = null;
        this.successMessage = 'Customer permanently deleted.';
      },
      error: (error) => {
        this.deletingId = null;
        this.errorMessage = error?.error?.message || 'Failed to permanently delete customer.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('active')) {
      return 'pill-success';
    }
    if (normalized.includes('deleted') || normalized.includes('inactive') || normalized.includes('blocked')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  get totalPages(): number {
    return getTotalPages(this.customers.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedCustomers();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedCustomers(): void {
    this.paginatedCustomers = getPaginatedItems(this.customers, this.currentPage, this.pageSize);
  }
}
