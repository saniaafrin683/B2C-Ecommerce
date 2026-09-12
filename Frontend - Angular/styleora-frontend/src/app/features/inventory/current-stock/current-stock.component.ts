import { Component, OnInit } from '@angular/core';
import { finalize } from 'rxjs/operators';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { CurrentStockSummary } from './current-stock.model';
import { CurrentStockService } from './current-stock.service';

@Component({
  selector: 'app-current-stock',
  templateUrl: './current-stock.component.html',
  styleUrls: ['./current-stock.component.css']
})
export class CurrentStockComponent implements OnInit {
  stockItems: CurrentStockSummary[] = [];
  filteredStockItems: CurrentStockSummary[] = [];
  loading = false;
  errorMessage = '';
  searchTerm = '';
  selectedCategory = 'all';

  constructor(
    private currentStockService: CurrentStockService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadCurrentStock();
  }

  get categories(): string[] {
    return Array.from(
      new Set(
        this.stockItems
          .map((item) => item.category)
          .filter((category) => !!category)
      )
    ).sort((left, right) => left.localeCompare(right));
  }

  get totalProducts(): number {
    return this.stockItems.length;
  }

  get lowStockCount(): number {
    return this.stockItems.filter((item) => item.stockStatus === 'Low Stock').length;
  }

  get outOfStockCount(): number {
    return this.stockItems.filter((item) => item.stockStatus === 'Out of Stock').length;
  }

  get totalUnitsInStock(): number {
    return this.stockItems.reduce((sum, item) => sum + Math.max(0, Number(item.currentStock || 0)), 0);
  }

  loadCurrentStock(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.currentStockService.getCurrentStock().pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (items) => {
        this.stockItems = items || [];
        this.applyFilters();
      },
      error: (error) => {
        console.error('Failed to load current stock', error);
        this.errorMessage = 'Failed to load current stock.';
        this.notificationService.showError(this.errorMessage);
        this.stockItems = [];
        this.filteredStockItems = [];
      }
    });
  }

  applyFilters(): void {
    const search = this.searchTerm.trim().toLowerCase();
    const category = this.selectedCategory.toLowerCase();

    this.filteredStockItems = this.stockItems.filter((item) => {
      const matchesSearch =
        !search ||
        item.productName.toLowerCase().includes(search) ||
        item.category.toLowerCase().includes(search);

      const matchesCategory =
        category === 'all' ||
        item.category.toLowerCase() === category;

      return matchesSearch && matchesCategory;
    });
  }

  onRefresh(): void {
    this.loadCurrentStock();
  }

  getStatusClass(status: string): string {
    if (status === 'Out of Stock') {
      return 'status-danger';
    }
    if (status === 'Low Stock') {
      return 'status-warning';
    }
    return 'status-success';
  }
}
