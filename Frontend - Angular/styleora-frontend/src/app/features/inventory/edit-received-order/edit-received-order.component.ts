import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
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
  selector: 'app-edit-received-order',
  templateUrl: './edit-received-order.component.html',
  styleUrls: ['./edit-received-order.component.css']
})
export class EditReceivedOrderComponent implements OnInit {

  orderForm: ReceivedOrder = {
    id: 0,
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

  loading = false;
  orderParamId: number = 0;
  warehouses: Warehouse[] = [];
  products: Product[] = [];
  readonly statusOptions = ['Pending', 'Completed'];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private receivedOrderService: ReceivedOrderService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private warehouseService: WarehouseService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadLookupData();
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.orderParamId = +id;
        this.loadOrder(this.orderParamId);
      } else {
        this.router.navigate(['/inventory/received-orders']);
      }
    });
  }

  loadOrder(id: number): void {
    this.loading = true;
    this.loadingService.show();

    this.receivedOrderService.getReceivedOrderById(id).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: ReceivedOrder) => {
        this.orderForm = res;
      },
      error: (err) => {
        console.error('Failed to load received order', err);
        this.notificationService.showError('Failed to load received order.');
      }
    });
  }

  onUpdate(): void {
    this.syncSelectedNames();
    this.loadingService.show();

    this.receivedOrderService.updateReceivedOrder(this.orderForm).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Received order updated successfully.');
        this.router.navigate(['/inventory/received-orders']);
      },
      error: (err) => {
        console.error('Failed to update received order', err);
        this.notificationService.showError('Failed to update received order.');
      }
    });
  }

  onReset(): void {
    this.loadOrder(this.orderParamId);
  }

  onCancel(): void {
    this.router.navigate(['/inventory/received-orders']);
  }

  onWarehouseChange(): void {
    const warehouse = this.warehouses.find((item) => item.id === this.orderForm.warehouseId) || null;
    this.orderForm.warehouseName = warehouse?.warehouseName || this.orderForm.warehouseName;
  }

  onProductChange(): void {
    const product = this.products.find((item) => item.id === this.orderForm.productId) || null;
    this.orderForm.productName = product?.name || this.orderForm.productName;
  }

  private loadLookupData(): void {
    this.warehouseService.getAllWarehouses().subscribe({
      next: (warehouses) => {
        this.warehouses = warehouses || [];
      },
      error: () => {
        this.notificationService.showError('Failed to load warehouses.');
      }
    });

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
