import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ProductService } from '../product.service';
import { Product } from '../product.model';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { getProductDisplayPrice, hasProductDiscount } from '../../../shared/utils/product-price.util';

@Component({
  selector: 'app-list',
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.css']
})
export class ListComponent implements OnInit {

  products: Product[] = [];
  paginatedProducts: Product[] = [];
  loading: boolean = false;
  errorMessage = '';
  successMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  constructor(
    private productService: ProductService,
    private route: ActivatedRoute,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe(() => {
      this.loadProducts();
    });
  }

  loadProducts(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.productService.getAllProducts().pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Product[]) => {
        this.products = res || [];
        this.currentPage = 1;
        this.updatePaginatedProducts();
      },
      error: () => {
        this.errorMessage = 'Failed to load products.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  get totalPages(): number {
    return getTotalPages(this.products.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedProducts();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  onEdit(productId: number | undefined): void {
    if (!productId) {
      this.errorMessage = 'Invalid product id.';
      this.notificationService.showError(this.errorMessage);
      return;
    }

    this.router.navigate(['/products/edit', productId]);
  }

  onDelete(productId: number | undefined): void {
    if (!productId) {
      this.errorMessage = 'Invalid product id.';
      this.notificationService.showError(this.errorMessage);
      return;
    }

    const confirmed = confirm('Are you sure you want to delete this product?');
    if (!confirmed) {
      return;
    }

    this.loadingService.show();

    this.productService.deleteProduct(productId).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Product deleted successfully.';
        this.errorMessage = '';
        this.notificationService.showSuccess(this.successMessage);
        this.loadProducts();
      },
      error: (error) => {
        this.successMessage = '';
        this.errorMessage = this.extractErrorMessage(error);
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  private extractErrorMessage(error: any): string {
    if (typeof error?.error === 'string') {
      try {
        const parsedError = JSON.parse(error.error);
        return parsedError?.message || 'Failed to delete product.';
      } catch {
        return error.error;
      }
    }

    if (error?.error?.message) {
      return error.error.message;
    }

    if (error?.error?.error) {
      return error.error.error;
    }

    if (error?.message) {
      return error.message;
    }

    return 'Failed to delete product.';
  }

  private updatePaginatedProducts(): void {
    this.paginatedProducts = getPaginatedItems(this.products, this.currentPage, this.pageSize);
  }

  getCurrentPrice(product: Product): number {
    return getProductDisplayPrice(product);
  }

  hasDiscount(product: Product): boolean {
    return hasProductDiscount(product);
  }
}