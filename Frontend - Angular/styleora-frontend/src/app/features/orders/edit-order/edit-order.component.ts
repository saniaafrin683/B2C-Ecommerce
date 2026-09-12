import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { Order, OrderItem } from '../order.model';
import { OrdersService } from '../orders.service';
import { Shipment } from '../../shipments/shipment.model';
import { ShipmentService } from '../../shipments/shipment.service';
import { ShippingMethod } from '../../shipping-methods/shipping-method.model';
import { ShippingMethodService } from '../../shipping-methods/shipping-method.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-edit-order',
  templateUrl: './edit-order.component.html',
  styleUrls: ['./edit-order.component.css']
})
export class EditOrderComponent implements OnInit {

  orderForm: Order = {
    id: 0,
    orderId: '',
    createdAt: '',
    customerName: '',
    customerEmail: '',
    customerPhone: '',
    priority: '',
    totalAmount: 0,
    subtotal: 0,
    tax: 0,
    discount: 0,
    shippingCost: 0,
    paymentMethod: '',
    paymentStatus: '',
    items: 0,
    quantity: 0,
    deliveryNumber: '',
    trackingNumber: '',
    orderStatus: '',
    shippingAddress: '',
    billingAddress: '',
    orderItems: []
  };

  initialFormSnapshot: string = '';
  loading = false;
  submitting = false;
  shipmentLoading = false;
  shipmentSubmitting = false;
  shipmentStatusSubmitting = false;
  orderParamId = 0;
  errorMessage = '';
  shipmentErrorMessage = '';
  shipmentId: number | null = null;

  priorityOptions: string[] = ['High', 'Medium', 'Low'];
  paymentStatusOptions: string[] = ['Pending', 'Paid', 'Unpaid', 'Refunded'];
  orderStatusOptions: string[] = ['Pending', 'Confirmed', 'In Progress', 'Shipped', 'Delivered', 'Cancelled'];
  shipmentStatusOptions: string[] = ['Pending', 'Packed', 'Shipped', 'Out For Delivery', 'Delivered'];
  courierOptions: string[] = ['Pathao', 'Paperfly', 'Sundarban', 'Steadfast', 'RedX', 'eCourier'];
  shippingMethods: ShippingMethod[] = [];
  shippingMethodsLoading = false;
  shipmentForm: Shipment = this.createInitialShipmentForm();
  initialShipmentSnapshot = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ordersService: OrdersService,
    private shipmentService: ShipmentService,
    private shippingMethodService: ShippingMethodService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');

    if (!idParam || isNaN(Number(idParam))) {
      this.notificationService.showError('Order id not found.');
      this.router.navigate(['/orders/list']);
      return;
    }

    this.orderParamId = Number(idParam);
    this.loadShippingMethods();
    this.loadOrder(this.orderParamId);
  }

  loadOrder(id: number): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    this.ordersService.getOrderById(id).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Order) => {
        this.orderForm = {
          id: res?.id ?? 0,
          orderId: res?.orderId ?? '',
          createdAt: res?.createdAt ?? res?.createdDate ?? '',
          customerName: res?.customerName ?? '',
          customerEmail: res?.customerEmail ?? res?.email ?? '',
          customerPhone: res?.customerPhone ?? res?.deliveryNumber ?? res?.phone ?? '',
          priority: res?.priority ?? '',
          totalAmount: Number(res?.totalAmount ?? res?.amount ?? 0),
          subtotal: Number(res?.subtotal ?? res?.totalAmount ?? res?.amount ?? 0),
          tax: Number(res?.tax ?? 0),
          discount: Number(res?.discount ?? 0),
          shippingCost: Number(res?.shippingCost ?? 0),
          paymentMethod: res?.paymentMethod ?? '',
          paymentStatus: res?.paymentStatus ?? 'Pending',
          items: Number(res?.items ?? res?.quantity ?? 0),
          quantity: Number(res?.quantity ?? res?.items ?? 0),
          deliveryNumber: res?.deliveryNumber ?? res?.customerPhone ?? '',
          trackingNumber: res?.trackingNumber ?? '',
          orderStatus: res?.orderStatus ?? res?.status ?? 'Pending',
          shippingAddress: res?.shippingAddress ?? res?.address ?? res?.customer_address ?? '',
          billingAddress: res?.billingAddress ?? res?.shippingAddress ?? res?.address ?? res?.customer_address ?? '',
          orderItems: (res?.orderItems || []).map((item: OrderItem) => ({
            id: item?.id ?? 0,
            productId: item?.productId ?? 0,
            productName: item?.productName ?? '',
            productImage: item?.productImage ?? '',
            size: item?.size ?? '',
            color: item?.color ?? '',
            unitPrice: Number(item?.unitPrice ?? 0),
            quantity: Number(item?.quantity ?? 0),
            lineTotal: Number(item?.lineTotal ?? ((item?.unitPrice ?? 0) * (item?.quantity ?? 0)))
          }))
        };

        this.initialFormSnapshot = JSON.stringify(this.orderForm);
        this.loadShipment(this.orderForm.id || this.orderParamId);
      },
      error: () => {
        this.errorMessage = 'Failed to load order details.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onUpdate(): void {
    this.submitting = true;
    this.errorMessage = '';
    this.loadingService.show();

    const payload: Order = {
      ...this.orderForm,
      customerName: (this.orderForm.customerName || '').trim(),
      customerEmail: (this.orderForm.customerEmail || '').trim(),
      customerPhone: (this.orderForm.customerPhone || '').trim(),
      shippingAddress: (this.orderForm.shippingAddress || '').trim(),
      billingAddress: (this.orderForm.billingAddress || '').trim(),
      paymentMethod: (this.orderForm.paymentMethod || '').trim(),
      deliveryNumber: (this.orderForm.deliveryNumber || this.orderForm.customerPhone || '').trim(),
      trackingNumber: (this.orderForm.trackingNumber || '').trim(),
      totalAmount: Number(this.orderForm.totalAmount ?? 0),
      subtotal: Number(this.orderForm.subtotal ?? 0),
      tax: Number(this.orderForm.tax ?? 0),
      discount: Number(this.orderForm.discount ?? 0),
      shippingCost: Number(this.orderForm.shippingCost ?? 0),
      items: Number(this.orderForm.items ?? 0),
      quantity: Number(this.orderForm.quantity ?? 0),
        orderItems: (this.orderForm.orderItems || []).map((item: OrderItem) => ({
          id: item?.id,
          productId: item?.productId,
          productName: item?.productName ?? '',
          productImage: item?.productImage ?? '',
          size: item?.size ?? '',
          color: item?.color ?? '',
        unitPrice: Number(item?.unitPrice ?? 0),
        quantity: Number(item?.quantity ?? 0),
        lineTotal: Number(item?.lineTotal ?? ((item?.unitPrice ?? 0) * (item?.quantity ?? 0)))
      }))
    };

    this.ordersService.updateOrder(this.orderParamId, payload).pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (updatedOrder) => {
        this.orderForm = updatedOrder;
        this.initialFormSnapshot = JSON.stringify(this.orderForm);
        this.notificationService.showSuccess('Order updated successfully.');
        this.router.navigate(['/orders/list']);
      },
      error: (error) => {
        this.errorMessage = error?.error?.message || 'Failed to update order.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onReset(): void {
    if (!this.initialFormSnapshot) {
      this.loadOrder(this.orderParamId);
      return;
    }

    this.orderForm = JSON.parse(this.initialFormSnapshot);
  }

  loadShipment(orderId: number): void {
    if (!orderId) {
      this.shipmentForm = this.createInitialShipmentForm();
      this.shipmentId = null;
      this.initialShipmentSnapshot = JSON.stringify(this.shipmentForm);
      return;
    }

    this.shipmentLoading = true;
    this.shipmentErrorMessage = '';

    this.shipmentService.getShipmentByOrderId(orderId).subscribe({
      next: (shipment) => {
        this.shipmentId = shipment.id ?? null;
        this.shipmentForm = {
          ...shipment,
          orderId,
          shippingMethodId: Number(shipment.shippingMethodId ?? 0) || undefined,
          shipmentStatus: shipment.shipmentStatus || shipment.status || 'Pending',
          shippedDate: this.formatDateTimeForInput(shipment.shippedDate || shipment.dispatchDate),
          estimatedDeliveryDate: this.formatDateTimeForInput(shipment.estimatedDeliveryDate),
          deliveredDate: this.formatDateTimeForInput(shipment.deliveredDate)
        };
        this.applyShippingMethodSelection();
        this.initialShipmentSnapshot = JSON.stringify(this.shipmentForm);
        this.shipmentLoading = false;
      },
      error: () => {
        this.shipmentId = null;
        this.shipmentForm = this.createInitialShipmentForm(orderId);
        this.applyShippingMethodSelection();
        this.initialShipmentSnapshot = JSON.stringify(this.shipmentForm);
        this.shipmentLoading = false;
      }
    });
  }

  onSaveShipment(): void {
    if (!this.orderForm.id) {
      return;
    }

    if (this.submitting || this.loading) {
      this.shipmentErrorMessage = 'Please wait until the latest order changes finish saving.';
      return;
    }

    if (!(this.shipmentForm.courierName || '').trim() || !(this.shipmentForm.trackingNumber || '').trim()) {
      this.shipmentErrorMessage = 'Courier name and tracking number are required.';
      return;
    }

    if (!Number(this.shipmentForm.shippingMethodId ?? 0)) {
      this.shipmentErrorMessage = 'Shipping method is required.';
      return;
    }

    this.shipmentSubmitting = true;
    this.shipmentErrorMessage = '';

    const payload = this.buildShipmentPayload();
    const request$ = this.shipmentId
      ? this.shipmentService.updateShipment(this.shipmentId, payload)
      : this.shipmentService.createShipment(payload);

    request$.subscribe({
      next: (shipment) => {
        this.shipmentSubmitting = false;
        this.notificationService.showSuccess(this.shipmentId ? 'Shipment updated successfully.' : 'Shipment created successfully.');
        this.shipmentId = shipment.id ?? null;
        this.shipmentForm = {
          ...shipment,
          orderId: this.orderForm.id,
          shippedDate: this.formatDateTimeForInput(shipment.shippedDate),
          estimatedDeliveryDate: this.formatDateTimeForInput(shipment.estimatedDeliveryDate),
          deliveredDate: this.formatDateTimeForInput(shipment.deliveredDate)
        };
        this.initialShipmentSnapshot = JSON.stringify(this.shipmentForm);
        this.orderForm.trackingNumber = shipment.trackingNumber || '';
        if (shipment.shipmentStatus === 'Delivered') {
          this.orderForm.orderStatus = 'Delivered';
        }
        this.loadOrder(this.orderForm.id || this.orderParamId);
      },
      error: (error) => {
        this.shipmentSubmitting = false;
        this.shipmentErrorMessage = error?.error?.message || 'Failed to save shipment.';
        this.notificationService.showError(this.shipmentErrorMessage);
      }
    });
  }

  onUpdateShipmentStatus(): void {
    if (!this.shipmentId) {
      this.onSaveShipment();
      return;
    }

    if (this.submitting || this.loading) {
      this.shipmentErrorMessage = 'Please wait until the latest order changes finish saving.';
      return;
    }

    this.shipmentStatusSubmitting = true;
    this.shipmentErrorMessage = '';

    this.shipmentService.updateShipmentStatus(this.shipmentId, this.shipmentForm.shipmentStatus || 'Pending').subscribe({
      next: (shipment) => {
        this.shipmentStatusSubmitting = false;
        this.notificationService.showSuccess('Shipment status updated successfully.');
        this.shipmentForm = {
          ...this.shipmentForm,
          ...shipment,
          shippedDate: this.formatDateTimeForInput(shipment.shippedDate),
          estimatedDeliveryDate: this.formatDateTimeForInput(shipment.estimatedDeliveryDate),
          deliveredDate: this.formatDateTimeForInput(shipment.deliveredDate)
        };
        this.initialShipmentSnapshot = JSON.stringify(this.shipmentForm);
        this.orderForm.trackingNumber = shipment.trackingNumber || this.orderForm.trackingNumber;
        if (shipment.shipmentStatus === 'Delivered') {
          this.orderForm.orderStatus = 'Delivered';
        }
        this.loadOrder(this.orderForm.id || this.orderParamId);
      },
      error: (error) => {
        this.shipmentStatusSubmitting = false;
        this.shipmentErrorMessage = error?.error?.message || 'Failed to update shipment status.';
        this.notificationService.showError(this.shipmentErrorMessage);
      }
    });
  }

  onResetShipment(): void {
    if (!this.initialShipmentSnapshot) {
      this.shipmentForm = this.createInitialShipmentForm(this.orderForm.id || this.orderParamId);
      return;
    }

    this.shipmentForm = JSON.parse(this.initialShipmentSnapshot);
    this.applyShippingMethodSelection();
    this.shipmentErrorMessage = '';
  }

  onShippingMethodChange(): void {
    const selectedMethod = this.getSelectedShippingMethod();
    if (!selectedMethod) {
      this.shipmentForm.courierName = '';
      return;
    }

    if (!(this.shipmentForm.courierName || '').trim()) {
      this.shipmentForm.courierName = selectedMethod.courierName || selectedMethod.name || '';
    }
  }

  onCancel(): void {
    this.router.navigate(['/orders/list']);
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

  getOrderItems(): OrderItem[] {
    return this.orderForm.orderItems || [];
  }

  private buildShipmentPayload(): Shipment {
    const selectedShippingMethodId = Number(this.shipmentForm.shippingMethodId ?? 0);
    const selectedMethod = this.shippingMethods.find((item) => item.id === selectedShippingMethodId);

    return {
      id: this.shipmentId ?? undefined,
      orderId: this.orderForm.id || this.orderParamId,
      shippingMethodId: selectedShippingMethodId || undefined,
      courierName: (this.shipmentForm.courierName || selectedMethod?.courierName || selectedMethod?.name || '').trim(),
      trackingNumber: (this.shipmentForm.trackingNumber || '').trim(),
      shipmentStatus: this.shipmentForm.shipmentStatus || this.shipmentForm.status || 'Pending',
      shippedDate: this.normalizeDateTime(this.shipmentForm.shippedDate || this.shipmentForm.dispatchDate || ''),
      estimatedDeliveryDate: this.normalizeDateTime(this.shipmentForm.estimatedDeliveryDate || ''),
      deliveredDate: this.normalizeDateTime(this.shipmentForm.deliveredDate || ''),
      remarks: (this.shipmentForm.remarks || '').trim()
    };
  }

  private formatDateTimeForInput(value: string | undefined): string {
    return value ? value.slice(0, 16) : '';
  }

  private normalizeDateTime(value: string): string {
    return value ? value.trim() : '';
  }

  private loadShippingMethods(): void {
    this.shippingMethodsLoading = true;

    this.shippingMethodService.getShippingMethods().subscribe({
      next: (shippingMethods) => {
        this.shippingMethods = (shippingMethods || []).filter((item) => (item.status || '').toUpperCase() !== 'INACTIVE');
        this.shippingMethodsLoading = false;
        this.applyShippingMethodSelection();
      },
      error: () => {
        this.shippingMethods = [];
        this.shippingMethodsLoading = false;
      }
    });
  }

  private applyShippingMethodSelection(): void {
    if (!this.shippingMethods.length) {
      return;
    }

    const selectedShippingMethodId = Number(this.shipmentForm.shippingMethodId ?? 0);
    if (selectedShippingMethodId) {
      const selectedMethod = this.shippingMethods.find((item) => item.id === selectedShippingMethodId);
      if (selectedMethod && !(this.shipmentForm.courierName || '').trim()) {
        this.shipmentForm.courierName = selectedMethod.courierName || selectedMethod.name || '';
      }
      return;
    }

    const courierName = (this.shipmentForm.courierName || '').trim().toLowerCase();
    if (!courierName) {
      return;
    }

    const matchedMethod = this.shippingMethods.find((item) =>
      (item.courierName || '').trim().toLowerCase() === courierName
      || (item.name || '').trim().toLowerCase() === courierName
    );

    if (matchedMethod) {
      this.shipmentForm.shippingMethodId = matchedMethod.id;
      this.shipmentForm.courierName = matchedMethod.courierName || matchedMethod.name || this.shipmentForm.courierName;
    }
  }

  private getSelectedShippingMethod(): ShippingMethod | undefined {
    const selectedShippingMethodId = Number(this.shipmentForm.shippingMethodId ?? 0);
    return this.shippingMethods.find((item) => item.id === selectedShippingMethodId);
  }

  private createInitialShipmentForm(orderId: number = 0): Shipment {
    return {
      orderId,
      shippingMethodId: undefined,
      courierName: '',
      trackingNumber: '',
      shipmentStatus: 'Pending',
      shippedDate: '',
      estimatedDeliveryDate: '',
      deliveredDate: '',
      remarks: ''
    };
  }
}
