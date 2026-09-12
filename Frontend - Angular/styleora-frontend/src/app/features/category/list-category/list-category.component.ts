import { Component, OnInit } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { forkJoin } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { CategoryService } from '../category.service';
import { Category } from '../category.model';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { SubCategoryService } from '../../sub-category/sub-category.service';
import { ProductService } from '../../products/product.service';
import { Product } from '../../products/product.model';
import { SubCategory } from '../../sub-category/sub-category.model';

@Component({
  selector: 'app-list-category',
  templateUrl: './list-category.component.html',
  styleUrls: ['./list-category.component.css']
})
export class ListCategoryComponent implements OnInit {

  categories: Category[] = [];
  paginatedCategories: Category[] = [];
  loading: boolean = false;
  errorMessage = '';
  successMessage = '';
  currentPage = 1;
  readonly pageSize = 10;
  private readonly categoryProductCounts = new Map<string, number>();
  private readonly categorySubCategoryCounts = new Map<number, number>();

  constructor(
    private categoryService: CategoryService,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private subCategoryService: SubCategoryService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadCategories();
  }

  loadCategories(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.categoryService.getAllCategories().pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Category[]) => {
        this.categories = res || [];
        this.currentPage = 1;
        this.updatePaginatedCategories();
        this.loadCategoryUsageMetadata();
      },
      error: () => {
        this.errorMessage = 'Failed to load categories.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  get totalPages(): number {
    return getTotalPages(this.categories.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedCategories();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  onEdit(categoryId: number | undefined): void {
    if (!categoryId) {
      this.errorMessage = 'Invalid category id.';
      this.notificationService.showError(this.errorMessage);
      return;
    }

    this.router.navigate(['/category/edit', categoryId]);
  }

  onDelete(categoryId: number | undefined): void {
    if (!categoryId) {
      this.errorMessage = 'Invalid category id.';
      this.notificationService.showError(this.errorMessage);
      return;
    }

    const confirmed = confirm('Are you sure you want to delete this category?');

    if (!confirmed) {
      return;
    }

    this.loadingService.show();

    this.categoryService.deleteCategory(categoryId).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Category deleted successfully.';
        this.notificationService.showSuccess(this.successMessage);
        this.loadCategories();
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = this.extractErrorMessage(error, 'Failed to delete category.');
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  isDeleteDisabled(category: Category): boolean {
    if (!category) {
      return true;
    }

    return this.getSubCategoryUsageCount(category) > 0 || this.getProductUsageCount(category) > 0;
  }

  getDeleteDisabledMessage(category: Category): string {
    if (!this.isDeleteDisabled(category)) {
      return 'Delete category';
    }

    return 'Cannot delete category because products or subcategories are using it.';
  }

  private updatePaginatedCategories(): void {
    this.paginatedCategories = getPaginatedItems(this.categories, this.currentPage, this.pageSize);
  }

  private loadCategoryUsageMetadata(): void {
    forkJoin({
      subCategories: this.subCategoryService.getAllSubCategories(),
      products: this.productService.getAllProducts()
    }).subscribe({
      next: ({ subCategories, products }: { subCategories: SubCategory[]; products: Product[] }) => {
        this.categorySubCategoryCounts.clear();
        this.categoryProductCounts.clear();

        (subCategories || []).forEach((subCategory) => {
          if (subCategory.categoryId == null) {
            return;
          }

          const currentCount = this.categorySubCategoryCounts.get(subCategory.categoryId) || 0;
          this.categorySubCategoryCounts.set(subCategory.categoryId, currentCount + 1);
        });

        (products || []).forEach((product) => {
          const key = this.normalizeCategoryTitle(product.category);
          if (!key) {
            return;
          }

          const currentCount = this.categoryProductCounts.get(key) || 0;
          this.categoryProductCounts.set(key, currentCount + 1);
        });
      },
      error: () => {
        this.categorySubCategoryCounts.clear();
        this.categoryProductCounts.clear();
      }
    });
  }

  private getProductUsageCount(category: Category): number {
    return this.categoryProductCounts.get(this.normalizeCategoryTitle(category.categoryTitle)) || 0;
  }

  private getSubCategoryUsageCount(category: Category): number {
    if (category.id == null) {
      return 0;
    }

    return this.categorySubCategoryCounts.get(category.id) || 0;
  }

  private normalizeCategoryTitle(value: string | null | undefined): string {
    return (value || '').trim().toLowerCase();
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
