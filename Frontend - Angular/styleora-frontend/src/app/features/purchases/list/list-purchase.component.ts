import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Purchase } from '../purchase.model';
import { PurchaseService } from '../purchase.service';
import { clampPage, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-list-purchase',
  templateUrl: './list-purchase.component.html',
  styleUrls: ['./list-purchase.component.css']
})
export class ListPurchaseComponent implements OnInit {
  readonly filterOptions = ['All Statuses', 'Pending', 'Received', 'Completed', 'Cancelled'];

  selectedFilter = 'All Statuses';
  currentPage = 1;
  readonly pageSize = 6;
  errorMessage = '';
  loading = false;

  purchases: Purchase[] = [];
  filteredPurchases: Purchase[] = [];

  constructor(
    private purchaseService: PurchaseService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadPurchases();
  }

  loadPurchases(): void {
    this.loading = true;
    this.purchaseService.getPurchases().subscribe({
      next: (purchases) => {
        this.purchases = purchases || [];
        this.applyFilter(this.selectedFilter);
        this.errorMessage = '';
        this.loading = false;
      },
      error: (error) => {
        console.error('Failed to load purchases', error);
        this.loading = false;
        this.errorMessage = 'Failed to load purchases.';
      }
    });
  }

  get paginatedPurchases(): Purchase[] {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    return this.filteredPurchases.slice(startIndex, startIndex + this.pageSize);
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.filteredPurchases.length / this.pageSize));
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  applyFilter(filter: string): void {
    this.selectedFilter = filter;

    if (filter === 'All Statuses') {
      this.filteredPurchases = [...this.purchases];
    } else {
      const normalizedFilter = filter.toLowerCase();
      this.filteredPurchases = this.purchases.filter((purchase) =>
        (purchase.purchaseStatus || '').toLowerCase() === normalizedFilter
      );
    }

    this.currentPage = 1;
  }

  getInitials(name: string): string {
    const parts = (name || '').trim().split(' ').filter(Boolean);
    if (!parts.length) {
      return 'NA';
    }
    if (parts.length === 1) {
      return parts[0].slice(0, 2).toUpperCase();
    }
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }

  getItemSummary(purchase: Purchase): string {
    return purchase.items
      .map((item) => `${item.productName} x${item.quantity}`)
      .join(', ');
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();

    if (normalized.includes('complete') || normalized.includes('receive')) {
      return 'pill-success';
    }

    if (normalized.includes('cancel')) {
      return 'pill-danger';
    }

    return 'pill-warning';
  }

  setPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
  }

  goToPrevious(): void {
    this.setPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.setPage(this.currentPage + 1);
  }

  onRefresh(): void {
    this.loadPurchases();
  }

  onView(purchase: Purchase): void {
    this.router.navigate(['/purchases/details', purchase.id]);
  }

  onEdit(purchase: Purchase): void {
    this.router.navigate(['/purchases/edit', purchase.id]);
  }

  onDelete(purchaseId: number): void {
    const confirmed = confirm('Delete this purchase record?');
    if (!confirmed) {
      return;
    }

    this.purchaseService.deletePurchase(purchaseId).subscribe({
      next: () => this.loadPurchases(),
      error: (error) => {
        console.error('Failed to delete purchase', error);
        this.errorMessage = typeof error?.error === 'string' && error.error.trim()
          ? error.error
          : 'Failed to delete purchase.';
      }
    });
  }
}
