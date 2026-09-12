import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { forkJoin } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { ReceivedOrderService } from '../received-orders/received-order.service';
import { WarehouseService } from './warehouse.service';
import { Warehouse } from './warehouse.model';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { ProductService } from '../../products/product.service';
import { Product } from '../../products/product.model';
import { ReceivedOrder } from '../received-orders/received-order.model';

@Component({
  selector: 'app-warehouse',
  templateUrl: './warehouse.component.html',
  styleUrls: ['./warehouse.component.css']
})
export class WarehouseComponent implements OnInit {

  warehouses: Warehouse[] = [];
  paginatedWarehouses: Warehouse[] = [];
  loading: boolean = false;
  errorMessage = '';
  successMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  totalProductItems: number = 0;
  inStockProduct: number = 0;
  outOfStockProduct: number = 0;
  totalReceivedOrders: number = 0;

  constructor(
    private warehouseService: WarehouseService,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private productService: ProductService,
    private receivedOrderService: ReceivedOrderService
  ) {}

  ngOnInit(): void {
    this.loadWarehouses();
  }

  loadWarehouses(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    forkJoin({
      warehouses: this.warehouseService.getAllWarehouses(),
      products: this.productService.getAllProducts(),
      receivedOrders: this.receivedOrderService.getAllReceivedOrders()
    }).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: ({ warehouses, products, receivedOrders }: { warehouses: Warehouse[]; products: Product[]; receivedOrders: ReceivedOrder[] }) => {
        this.warehouses = warehouses || [];
        this.currentPage = 1;
        this.updatePaginatedWarehouses();
        this.calculateSummary(products || [], receivedOrders || []);
      },
      error: (err) => {
        console.error('Failed to load warehouses', err);
        this.errorMessage = 'Failed to load warehouses.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  get totalPages(): number {
    return getTotalPages(this.warehouses.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedWarehouses();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  calculateSummary(products: Product[], receivedOrders: ReceivedOrder[]): void {
    this.totalProductItems = (products || []).reduce(
      (sum, item) => sum + Math.max(0, Number(item.stock || 0)),
      0
    );

    this.inStockProduct = (products || []).filter(
      item => Number(item.stock || 0) > 0
    ).length;

    this.outOfStockProduct = (products || []).filter(
      item => Number(item.stock || 0) <= 0
    ).length;

    this.totalReceivedOrders = (receivedOrders || []).length;
  }

  onDetails(id: number | undefined): void {
    if (!id) {
      return;
    }

    this.router.navigate(['/inventory/warehouse-details', id]);
  }

  onEdit(id: number | undefined): void {
    if (!id) {
      return;
    }

    this.router.navigate(['/inventory/edit-warehouse', id]);
  }

  onDelete(id: number | undefined): void {
    if (!id) {
      return;
    }

    const confirmed = confirm('Are you sure you want to delete this warehouse?');
    if (!confirmed) {
      return;
    }

    this.loadingService.show();

    this.warehouseService.deleteWarehouse(id).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Warehouse deleted successfully.';
        this.notificationService.showSuccess(this.successMessage);
        this.loadWarehouses();
      },
      error: (err) => {
        console.error('Failed to delete warehouse', err);
        this.errorMessage = 'Failed to delete warehouse.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onRefresh(): void {
    this.loadWarehouses();
  }

  private updatePaginatedWarehouses(): void {
    this.paginatedWarehouses = getPaginatedItems(this.warehouses, this.currentPage, this.pageSize);
  }
}
