import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ReceivedOrderService } from '../received-orders/received-order.service';
import { ReceivedOrder } from '../received-orders/received-order.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { WarehouseService } from '../warehouse/warehouse.service';
import { Warehouse } from '../warehouse/warehouse.model';
import { ProductService } from '../../products/product.service';
import { Product } from '../../products/product.model';

@Component({
  selector: 'app-create-received-order',
  templateUrl: './create-received-order.component.html',
  styleUrls: ['./create-received-order.component.css']
})
export class CreateReceivedOrderComponent implements OnInit {

  orderForm: ReceivedOrder = {
    orderNo: '',
    supplierName: '',
    warehouseId: null,
    warehouseName: '',
    productId: null,
    productName: '',
    quantity: 0,
    receivedDate: '',
    status: 'Pending',
    totalAmount: 0
  };
  warehouses: Warehouse[] = [];
  products: Product[] = [];
  loadingOptions = false;
  readonly statusOptions = ['Pending', 'Completed'];

  constructor(
    private receivedOrderService: ReceivedOrderService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private router: Router,
    private warehouseService: WarehouseService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadLookupData();
  }

  onSave(): void {
    this.syncSelectedNames();
    this.loadingService.show();

    this.receivedOrderService.createReceivedOrder(this.orderForm).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Received order created successfully.');
        this.router.navigate(['/inventory/received-orders']);
      },
      error: (err) => {
        console.error('Failed to create received order', err);
        this.notificationService.showError('Failed to create received order.');
      }
    });
  }

  onReset(): void {
    this.orderForm = {
      orderNo: '',
      supplierName: '',
      warehouseId: null,
      warehouseName: '',
      productId: null,
      productName: '',
      quantity: 0,
      receivedDate: '',
      status: 'Pending',
      totalAmount: 0
    };
  }

  onCancel(): void {
    this.router.navigate(['/inventory/received-orders']);
  }

  onWarehouseChange(): void {
    const warehouse = this.warehouses.find((item) => item.id === this.orderForm.warehouseId) || null;
    this.orderForm.warehouseName = warehouse?.warehouseName || '';
  }

  onProductChange(): void {
    const product = this.products.find((item) => item.id === this.orderForm.productId) || null;
    this.orderForm.productName = product?.name || '';
  }

  private loadLookupData(): void {
    this.loadingOptions = true;
    this.loadingService.show();

    this.warehouseService.getAllWarehouses().pipe(
      finalize(() => {
        this.loadingOptions = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (warehouses) => {
        this.warehouses = warehouses || [];
        this.loadProducts();
      },
      error: () => {
        this.notificationService.showError('Failed to load warehouses.');
      }
    });
  }

  private loadProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.products = products || [];
      },
      error: () => {
        this.notificationService.showError('Failed to load products.');
      }
    });
  }

  private syncSelectedNames(): void {
    this.onWarehouseChange();
    this.onProductChange();
  }
}
