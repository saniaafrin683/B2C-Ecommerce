import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PurchaseOrder, PurchaseOrderLineItem } from '../purchase-order.model';
import { PurchaseOrderService } from '../purchase-order.service';

@Component({
  selector: 'app-purchase-order',
  templateUrl: './purchase-order.component.html',
  styleUrls: ['./purchase-order.component.css']
})
export class PurchaseOrderComponent implements OnInit {
  purchaseOrders: PurchaseOrder[] = [];
  selectedOrder: PurchaseOrder | null = null;
  loading = false;
  errorMessage = '';

  readonly orderStatuses = ['Pending', 'Approved', 'Received', 'Completed', 'Cancelled'];
  readonly paymentStatuses = ['Pending', 'Paid', 'Partial', 'Refunded'];
  readonly paymentMethods = ['Credit Card', 'Bank Transfer', 'Cash on Delivery', 'PayPal'];

  constructor(
    private purchaseOrderService: PurchaseOrderService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadPurchaseOrders();
  }

  get totalOrders(): number {
    return this.purchaseOrders.length;
  }

  get pendingOrders(): number {
    return this.purchaseOrders.filter((order) => this.matches(order.orderStatus, 'pending')).length;
  }

  get completedOrders(): number {
    return this.purchaseOrders.filter((order) =>
      this.matches(order.orderStatus, 'received') || this.matches(order.orderStatus, 'completed')
    ).length;
  }

  get cancelledOrders(): number {
    return this.purchaseOrders.filter((order) => this.matches(order.orderStatus, 'cancel')).length;
  }

  loadPurchaseOrders(): void {
    this.loading = true;
    this.errorMessage = '';

    this.purchaseOrderService.getPurchaseOrders().subscribe({
      next: (orders) => {
        this.purchaseOrders = orders;
        this.loading = false;

        if (this.selectedOrder) {
          this.selectedOrder = this.purchaseOrders.find((order) => order.id === this.selectedOrder?.id) || null;
        }
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load purchase orders.';
      }
    });
  }

  openCreateForm(): void {
    this.router.navigate(['/purchases/order/create']);
  }

  onView(order: PurchaseOrder): void {
    this.selectedOrder = order;
  }

  onEdit(order: PurchaseOrder): void {
    this.selectedOrder = order;
    this.router.navigate(['/purchases/order/create'], {
      state: {
        mode: 'edit',
        purchaseOrderId: order.id
      }
    });
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this purchase order?');
    if (!confirmed) {
      return;
    }

    this.purchaseOrderService.deletePurchaseOrder(id).subscribe({
      next: () => {
        if (this.selectedOrder?.id === id) {
          this.selectedOrder = null;
        }
        this.loadPurchaseOrders();
      },
      error: () => {
        this.errorMessage = 'Failed to delete purchase order.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();

    if (normalized.includes('received') || normalized.includes('complete') || normalized.includes('paid')) {
      return 'pill-success';
    }

    if (normalized.includes('cancel') || normalized.includes('refund')) {
      return 'pill-danger';
    }

    return 'pill-warning';
  }

  getItemSummary(order: PurchaseOrder): string {
    return order.items.map((item) => `${item.product} x${item.quantity}`).join(', ');
  }

  getItemCount(order: PurchaseOrder): number {
    return order.items.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
  }

  private matches(value: string, expected: string): boolean {
    return (value || '').toLowerCase().includes(expected.toLowerCase());
  }
}
