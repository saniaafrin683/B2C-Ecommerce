import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ReceivedOrderService } from './received-order.service';
import { ReceivedOrder } from './received-order.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-received-orders',
  templateUrl: './received-orders.component.html',
  styleUrls: ['./received-orders.component.css']
})
export class ReceivedOrdersComponent implements OnInit {

  receivedOrders: ReceivedOrder[] = [];
  loading = false;
  errorMessage = '';
  successMessage = '';
  updatingStatusId: number | null = null;

  totalOrders = 0;
  completedOrders = 0;
  pendingOrders = 0;
  totalReceivedAmount = 0;
  readonly statusOptions = ['Pending', 'Completed'];

  constructor(
    private receivedOrderService: ReceivedOrderService,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadReceivedOrders();
  }

  loadReceivedOrders(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.receivedOrderService.getAllReceivedOrders().pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: ReceivedOrder[]) => {
        this.receivedOrders = res || [];
        this.calculateSummary();
      },
      error: (err) => {
        console.error('Failed to load received orders', err);
        this.errorMessage = 'Failed to load received orders.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  calculateSummary(): void {
    this.totalOrders = this.receivedOrders.length;

    this.completedOrders = this.receivedOrders.filter(
      item => (item.status || '').toLowerCase() === 'completed'
    ).length;

    this.pendingOrders = this.receivedOrders.filter(
      item => (item.status || '').toLowerCase() === 'pending'
    ).length;

    this.totalReceivedAmount = this.receivedOrders.reduce(
      (sum, item) => sum + (item.totalAmount || 0),
      0
    );
  }

  onDetails(id: number | undefined): void {
    if (!id) {
      return;
    }

    this.router.navigate(['/inventory/received-order-details', id]);
  }

  onEdit(id: number | undefined): void {
    if (!id) {
      return;
    }

    this.router.navigate(['/inventory/edit-received-order', id]);
  }

  onDelete(id: number | undefined): void {
    if (!id) {
      return;
    }

    const confirmed = confirm('Are you sure you want to delete this received order?');
    if (!confirmed) {
      return;
    }

    this.loadingService.show();

    this.receivedOrderService.deleteReceivedOrder(id).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Received order deleted successfully.';
        this.notificationService.showSuccess(this.successMessage);
        this.loadReceivedOrders();
      },
      error: (err) => {
        console.error('Failed to delete received order', err);
        this.errorMessage = 'Failed to delete received order.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onStatusChange(order: ReceivedOrder, status: string): void {
    if (!order.id || !status || status === order.status) {
      return;
    }

    this.errorMessage = '';
    this.successMessage = '';
    this.updatingStatusId = order.id;

    this.receivedOrderService.updateReceivedOrderStatus(order.id, status).pipe(
      finalize(() => {
        this.updatingStatusId = null;
      })
    ).subscribe({
      next: (updatedOrder) => {
        const index = this.receivedOrders.findIndex((item) => item.id === updatedOrder.id);
        if (index >= 0) {
          this.receivedOrders[index] = updatedOrder;
          this.receivedOrders = [...this.receivedOrders];
        }
        this.calculateSummary();
        this.successMessage = status === 'Completed'
          ? 'Received order completed and stock updated successfully.'
          : 'Received order status updated successfully.';
        this.notificationService.showSuccess(this.successMessage);
      },
      error: (err) => {
        console.error('Failed to update received order status', err);
        this.errorMessage = err?.error?.message || 'Failed to update received order status.';
        this.notificationService.showError(this.errorMessage);
        this.loadReceivedOrders();
      }
    });
  }
}
