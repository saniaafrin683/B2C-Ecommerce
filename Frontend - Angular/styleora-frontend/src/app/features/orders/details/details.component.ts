import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { Order, OrderItem } from '../order.model';
import { OrdersService } from '../orders.service';
import { Shipment } from '../../shipments/shipment.model';
import { ShipmentService } from '../../shipments/shipment.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-details',
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.css']
})
export class DetailsComponent implements OnInit {

  orderId!: number;
  order: Order | null = null;
  shipment: Shipment | null = null;
  shipmentLoading = false;
  loading = true;
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ordersService: OrdersService,
    private shipmentService: ShipmentService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');

    if (!idParam || isNaN(Number(idParam))) {
      this.loading = false;
      this.errorMessage = 'Invalid order id.';
      return;
    }

    this.orderId = Number(idParam);
    this.loadOrderDetails();
  }

  loadOrderDetails(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.ordersService.getOrderById(this.orderId).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (response: Order) => {
        this.order = response;
        this.loadShipmentDetails();
      },
      error: () => {
        this.errorMessage = 'Failed to load order details.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/orders/list']);
  }

  goToEdit(): void {
    if (this.order?.id != null) {
      this.router.navigate(['/orders/edit', this.order.id]);
    }
  }

  getDisplayOrderId(): string {
    if (!this.order) {
      return '-';
    }

    return this.order.orderId || (this.order.id != null ? `#${this.order.id}` : '-');
  }

  getCustomerName(): string {
    return this.order?.customerName || 'Not Available';
  }

  getCustomerEmail(): string {
    return this.order?.customerEmail || this.order?.email || 'Not Available';
  }

  getCustomerPhone(): string {
    return this.order?.customerPhone || this.order?.deliveryNumber || this.order?.phone || 'Not Available';
  }

  getOrderStatus(): string {
    return this.order?.orderStatus || this.order?.status || 'Pending';
  }

  getPaymentStatus(): string {
    return this.order?.paymentStatus || 'Pending';
  }

  getPaymentMethod(): string {
    return this.order?.paymentMethod || 'Not Available';
  }

  getShippingAddress(): string {
    return this.order?.shippingAddress || this.order?.address || this.order?.customer_address || 'Not Available';
  }

  getBillingAddress(): string {
    return this.order?.billingAddress || this.getShippingAddress();
  }

  getTotalAmount(): number {
    return Number(this.order?.totalAmount ?? this.order?.amount ?? 0);
  }

  getSubtotal(): number {
    return Number(this.order?.subtotal ?? this.getTotalAmount());
  }

  getTax(): number {
    return Number(this.order?.tax ?? 0);
  }

  getDiscount(): number {
    return Number(this.order?.discount ?? 0);
  }

  getShippingCost(): number {
    return Number(this.order?.shippingCost ?? 0);
  }

  getQuantity(): number {
    return Number(this.order?.quantity ?? this.order?.items ?? 1);
  }

  getOrderItems(): OrderItem[] {
    return this.order?.orderItems || [];
  }

  getTotalItemCount(): number {
    const orderItems = this.getOrderItems();

    if (!orderItems.length) {
      return this.getQuantity();
    }

    return orderItems.reduce((sum, item) => sum + Number(item.quantity ?? 0), 0);
  }

  getItemPrice(item: OrderItem): number {
    return Number(item.unitPrice ?? 0);
  }

  getItemTotal(item: OrderItem): number {
    return Number(item.lineTotal ?? ((item.unitPrice ?? 0) * (item.quantity ?? 0)));
  }

  getFormattedDate(value: string | undefined): string {
    if (!value) {
      return 'Not Available';
    }

    const date = new Date(value);

    if (isNaN(date.getTime())) {
      return value;
    }

    return date.toLocaleString();
  }

  loadShipmentDetails(): void {
    if (!this.order?.id) {
      this.shipment = null;
      return;
    }

    this.shipmentLoading = true;
    this.shipmentService.getShipmentByOrderId(this.order.id).subscribe({
      next: (shipment) => {
        this.shipment = shipment;
        this.shipmentLoading = false;
      },
      error: () => {
        this.shipment = null;
        this.shipmentLoading = false;
      }
    });
  }

  getShipmentStatus(): string {
    return this.shipment?.shipmentStatus || this.order?.shipmentStatus || 'Pending';
  }

  goToShipmentEdit(): void {
    if (this.order?.id != null) {
      this.router.navigate(['/orders/edit', this.order.id]);
    }
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();

    if (
      normalized.includes('deliver') ||
      normalized.includes('paid') ||
      normalized.includes('complete')
    ) {
      return 'status-success';
    }

    if (
      normalized.includes('ship') ||
      normalized.includes('process') ||
      normalized.includes('progress')
    ) {
      return 'status-info';
    }

    if (
      normalized.includes('pending') ||
      normalized.includes('review')
    ) {
      return 'status-warning';
    }

    if (
      normalized.includes('cancel') ||
      normalized.includes('refund') ||
      normalized.includes('failed') ||
      normalized.includes('unpaid')
    ) {
      return 'status-danger';
    }

    return 'status-default';
  }

  getInitials(name: string): string {
    if (!name || name === 'Not Available') {
      return 'NA';
    }

    const parts = name.trim().split(' ').filter(Boolean);

    if (parts.length === 1) {
      return parts[0].substring(0, 2).toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  isStepCompleted(step: string): boolean {
    const status = this.getOrderStatus().toLowerCase();

    if (step === 'placed') {
      return true;
    }

    if (step === 'confirmed') {
      return status.includes('confirm') ||
             status.includes('process') ||
             status.includes('progress') ||
             status.includes('ship') ||
             status.includes('deliver');
    }

    if (step === 'processing') {
      return status.includes('process') ||
             status.includes('progress') ||
             status.includes('ship') ||
             status.includes('deliver');
    }

    if (step === 'shipped') {
      return status.includes('ship') || status.includes('deliver');
    }

    if (step === 'delivered') {
      return status.includes('deliver') || status.includes('complete');
    }

    return false;
  }
}
