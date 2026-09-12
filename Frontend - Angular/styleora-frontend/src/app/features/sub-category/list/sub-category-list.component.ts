import { Component, OnInit } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { forkJoin } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { SubCategory } from '../sub-category.model';
import { SubCategoryService } from '../sub-category.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { ProductService } from '../../products/product.service';
import { Product } from '../../products/product.model';

@Component({
  selector: 'app-sub-category-list',
  templateUrl: './sub-category-list.component.html',
  styleUrls: ['./sub-category-list.component.css']
})
export class SubCategoryListComponent implements OnInit {
  subCategories: SubCategory[] = [];
  paginatedSubCategories: SubCategory[] = [];
  loading = false;
  errorMessage = '';
  successMessage = '';
  currentPage = 1;
  readonly pageSize = 10;
  private readonly subCategoryProductCounts = new Map<number, number>();

  constructor(
    private subCategoryService: SubCategoryService,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadSubCategories();
  }

  loadSubCategories(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.subCategoryService.getAllSubCategories().pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (subCategories) => {
        this.subCategories = subCategories || [];
        this.currentPage = 1;
        this.updatePaginatedSubCategories();
        this.loadUsageMetadata();
      },
      error: () => {
        this.errorMessage = 'Failed to load sub categories.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onEdit(id: number | undefined): void {
    if (!id) {
      this.errorMessage = 'Invalid sub category id.';
      this.notificationService.showError(this.errorMessage);
      return;
    }

    this.router.navigate(['/sub-category/edit', id]);
  }

  onDelete(id: number | undefined): void {
    if (!id) {
      this.errorMessage = 'Invalid sub category id.';
      this.notificationService.showError(this.errorMessage);
      return;
    }

    if (!confirm('Are you sure you want to delete this sub category?')) {
      return;
    }

    this.loadingService.show();

    this.subCategoryService.deleteSubCategory(id).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Sub category deleted successfully.';
        this.notificationService.showSuccess(this.successMessage);
        this.loadSubCategories();
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = this.extractErrorMessage(error, 'Failed to delete sub category.');
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  isDeleteDisabled(item: SubCategory): boolean {
    if (!item?.id) {
      return true;
    }

    return (this.subCategoryProductCounts.get(item.id) || 0) > 0;
  }

  getDeleteDisabledMessage(item: SubCategory): string {
    if (!this.isDeleteDisabled(item)) {
      return 'Delete sub category';
    }

    return 'Cannot delete sub category because products are using it.';
  }

  getStockClass(stock: number | null | undefined): string {
    const value = stock || 0;

    if (value <= 0) {
      return 'stock-pill stock-empty';
    }

    if (value < 10) {
      return 'stock-pill stock-low';
    }

    return 'stock-pill';
  }

  get totalPages(): number {
    return getTotalPages(this.subCategories.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedSubCategories();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedSubCategories(): void {
    this.paginatedSubCategories = getPaginatedItems(this.subCategories, this.currentPage, this.pageSize);
  }

  private loadUsageMetadata(): void {
    forkJoin({
      products: this.productService.getAllProducts()
    }).subscribe({
      next: ({ products }: { products: Product[] }) => {
        this.subCategoryProductCounts.clear();

        (products || []).forEach((product) => {
          if (product.subCategoryId == null) {
            return;
          }

          const currentCount = this.subCategoryProductCounts.get(product.subCategoryId) || 0;
          this.subCategoryProductCounts.set(product.subCategoryId, currentCount + 1);
        });
      },
      error: () => {
        this.subCategoryProductCounts.clear();
      }
    });
  }

  private extractErrorMessage(error: HttpErrorResponse, fallbackMessage: string): string {
    if (typeof error?.error === 'string' && error.error.trim()) {
      try {
        const parsed = JSON.parse(error.error);
        if (parsed?.message) {
          return parsed.message;
        }
      } catch {
        return error.error;
      }
    }

    if (error?.error?.message) {
      return error.error.message;
    }

    return fallbackMessage;
  }
}
