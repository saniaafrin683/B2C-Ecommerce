import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { Order } from '../order.model';
import { OrdersService } from '../orders.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-orders-list',
  templateUrl: './orders-list.component.html',
  styleUrls: ['./orders-list.component.css']
})
export class OrdersListComponent implements OnInit {
  readonly orderStatuses: string[];
  selectedStatuses: Record<number, string> = {};

  orders: Order[] = [];
  filteredOrders: Order[] = [];
  paginatedOrders: Order[] = [];
  loading = false;
  errorMessage = '';
  successMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  paymentRefundCount = 0;
  orderCancelCount = 0;
  orderShippedCount = 0;
  orderDeliveringCount = 0;
  pendingReviewCount = 0;
  pendingPaymentCount = 0;
  deliveredCount = 0;
  inProgressCount = 0;
  updatingStatusOrderId: number | null = null;

  constructor(
    private ordersService: OrdersService,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {
    this.orderStatuses = this.ordersService.getAvailableOrderStatuses();
  }

  ngOnInit(): void {
    this.loadOrders();
  }

  loadOrders(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.ordersService.getAllOrders().pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (response: Order[]) => {
        this.orders = response || [];
        this.filteredOrders = [...this.orders];
        this.selectedStatuses = this.orders.reduce<Record<number, string>>((accumulator, order) => {
          if (order.id != null) {
            accumulator[order.id] = this.getStatus(order);
          }
          return accumulator;
        }, {});
        this.currentPage = 1;
        this.updatePaginatedOrders();
        this.calculateSummaryCounts();
      },
      error: () => {
        this.errorMessage = 'Failed to load orders.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  calculateSummaryCounts(): void {
    this.paymentRefundCount = this.orders.filter(order =>
      this.containsText(order.paymentStatus, 'refund')
    ).length;

    this.orderCancelCount = this.orders.filter(order =>
      this.containsText(order.orderStatus || order.status, 'cancel')
    ).length;

    this.orderShippedCount = this.orders.filter(order =>
      this.containsText(order.orderStatus || order.status, 'shipped')
    ).length;

    this.orderDeliveringCount = this.orders.filter(order =>
      this.containsText(order.orderStatus || order.status, 'delivering')
    ).length;

    this.pendingReviewCount = this.orders.filter(order =>
      this.containsText(order.orderStatus || order.status, 'review')
    ).length;

    this.pendingPaymentCount = this.orders.filter(order =>
      this.containsText(order.paymentStatus, 'pending') ||
      this.containsText(order.paymentStatus, 'unpaid')
    ).length;

    this.deliveredCount = this.orders.filter(order =>
      this.containsText(order.orderStatus || order.status, 'delivered')
    ).length;

    this.inProgressCount = this.orders.filter(order =>
      this.containsText(order.orderStatus || order.status, 'progress') ||
      this.containsText(order.orderStatus || order.status, 'processing')
    ).length;
  }

  containsText(value: string | undefined, text: string): boolean {
    return (value || '').toLowerCase().includes(text.toLowerCase());
  }

  getPriorityFromStatus(status: string): string {
    const normalized = (status || '').toLowerCase();

    if (normalized.includes('cancel') || normalized.includes('refund')) {
      return 'High';
    }

    if (normalized.includes('pending') || normalized.includes('review')) {
      return 'Medium';
    }

    return 'Low';
  }

  getStatus(order: Order): string {
    return order.orderStatus || order.status || 'Pending';
  }

  isStatusUpdating(orderId: number | undefined): boolean {
    return orderId != null && this.updatingStatusOrderId === orderId;
  }

  getSelectedStatus(order: Order): string {
    if (order.id == null) {
      return this.getStatus(order);
    }

    return this.selectedStatuses[order.id] || this.getStatus(order);
  }

  getStatusClass(status: string | undefined): Record<string, boolean> {
    const normalizedStatus = this.getNormalizedStatus(status);
    return {
      'status-confirmed': normalizedStatus === 'Confirmed',
      'status-shipped': normalizedStatus === 'Shipped',
      'status-delivered': normalizedStatus === 'Delivered',
      'status-progress': normalizedStatus === 'Processing',
      'status-pending': normalizedStatus === 'Pending',
      'status-cancelled': normalizedStatus === 'Cancelled'
    };
  }

  getAmount(order: Order): number {
    return Number(order.totalAmount ?? order.amount ?? 0);
  }

  get totalPages(): number {
    return getTotalPages(this.filteredOrders.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedOrders();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  onDetails(id: number | undefined): void {
    if (id === undefined || id === null) {
      return;
    }
    this.router.navigate(['/orders/details', id]);
  }

  onEdit(id: number | undefined): void {
    if (id === undefined || id === null) {
      return;
    }
    this.router.navigate(['/orders/edit', id]);
  }

  onDelete(id: number | undefined): void {
    if (id === undefined || id === null) {
      return;
    }

    const confirmed = confirm('Are you sure you want to delete this order?');
    if (!confirmed) {
      return;
    }

    this.loadingService.show();

    this.ordersService.deleteOrder(id).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Order deleted successfully.';
        this.notificationService.showSuccess(this.successMessage);
        this.loadOrders();
      },
      error: (error) => {
        this.errorMessage = error?.error?.message || error?.error || 'Failed to delete order.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onStatusChange(order: Order, nextStatus: string): void {
    if (order.id == null) {
      return;
    }

    const currentStatus = this.getStatus(order);
    const normalizedNextStatus = this.getNormalizedStatus(nextStatus);
    if (currentStatus === normalizedNextStatus) {
      this.selectedStatuses[order.id] = currentStatus;
      return;
    }

    this.errorMessage = '';
    this.successMessage = '';
    this.updatingStatusOrderId = order.id;
    this.selectedStatuses[order.id] = normalizedNextStatus;

    this.ordersService.updateOrderStatus(order.id, normalizedNextStatus).pipe(
      finalize(() => {
        this.updatingStatusOrderId = null;
      })
    ).subscribe({
      next: (updatedOrder) => {
        const normalizedStatus = this.getStatus(updatedOrder);
        if (normalizedStatus !== normalizedNextStatus) {
          order.orderStatus = currentStatus;
          order.status = currentStatus;
          this.selectedStatuses[order.id!] = currentStatus;
          this.errorMessage = 'Order status was not persisted by the server.';
          this.notificationService.showError(this.errorMessage);
          return;
        }

        order.orderStatus = normalizedStatus;
        order.status = normalizedStatus;
        order.paymentStatus = updatedOrder.paymentStatus || order.paymentStatus;
        this.selectedStatuses[order.id!] = normalizedStatus;
        this.successMessage = `Order ${order.orderId || order.id} status updated to ${normalizedStatus}.`;
        this.notificationService.showSuccess(this.successMessage);
        this.loadOrders();
      },
      error: () => {
        order.orderStatus = currentStatus;
        order.status = currentStatus;
        this.selectedStatuses[order.id!] = currentStatus;
        this.errorMessage = 'Failed to update order status.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  get hasOrders(): boolean {
    return this.filteredOrders.length > 0;
  }

  private updatePaginatedOrders(): void {
    this.paginatedOrders = getPaginatedItems(this.filteredOrders, this.currentPage, this.pageSize);
  }

  private getNormalizedStatus(status: string | undefined): string {
    const rawStatus = (status || '').trim().toLowerCase();

    if (!rawStatus || rawStatus === 'pending review') {
      return 'Pending';
    }

    if (rawStatus === 'in progress') {
      return 'Processing';
    }

    const matchedStatus = this.orderStatuses.find((item) => item.toLowerCase() === rawStatus);
    return matchedStatus || 'Pending';
  }
}
