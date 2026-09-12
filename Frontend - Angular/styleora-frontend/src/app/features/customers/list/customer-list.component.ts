import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Customer } from '../customer.model';
import { CustomerService } from '../customer.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-customer-list',
  templateUrl: './customer-list.component.html',
  styleUrls: ['./customer-list.component.css']
})
export class CustomerListComponent implements OnInit {
  customers: Customer[] = [];
  paginatedCustomers: Customer[] = [];
  loading = false;
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  constructor(
    private customerService: CustomerService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCustomers();
  }

  get totalCustomers(): number {
    return this.customers.length;
  }

  get activeCustomers(): number {
    return this.customers.filter((item) => (item.status || '').trim().toUpperCase() === 'ACTIVE').length;
  }

  get totalOrdersCount(): number {
    return this.customers.reduce((sum, item) => sum + Number(item.totalOrders || 0), 0);
  }

  get totalSpendAmount(): number {
    return this.customers.reduce((sum, item) => sum + Number(item.totalSpend || 0), 0);
  }

  loadCustomers(): void {
    this.loading = true;
    this.errorMessage = '';

    this.customerService.getCustomers().subscribe({
      next: (customers) => {
        this.customers = customers || [];
        this.currentPage = 1;
        this.updatePaginatedCustomers();
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load customers', err);
        this.loading = false;
        this.errorMessage = err?.error?.message || err?.message || 'Failed to load customers.';
      }
    });
  }

  onCreate(): void {
    this.router.navigate(['/customers/create']);
  }

  onView(customer: Customer): void {
    this.router.navigate(['/customers/details', customer.id]);
  }

  onEdit(customer: Customer): void {
    this.router.navigate(['/customers/edit', customer.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to move this customer to Restore Customers?');
    if (!confirmed) {
      return;
    }

    this.customerService.deleteCustomer(id).subscribe({
      next: () => {
        this.loadCustomers();
      },
      error: (err) => {
        console.error('Failed to move customer to Restore Customers', err);
        this.errorMessage = err?.error?.message || err?.message || 'Failed to move customer to Restore Customers.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').trim().toUpperCase();
    if (normalized === 'ACTIVE') {
      return 'pill-success';
    }
    if (normalized === 'INACTIVE' || normalized === 'SUSPENDED' || normalized === 'DELETED') {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getInitials(name: string): string {
    if (!name) {
      return 'CU';
    }

    return name
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map(part => part.charAt(0).toUpperCase())
      .join('');
  }

  getLocationLabel(customer: Customer): string {
    const city = customer.city || '';
    const country = customer.country || '';

    if (city && country) {
      return `${city}, ${country}`;
    }

    return city || country || 'Location not set';
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
