import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';

import { Shipment } from '../shipment.model';
import { ShipmentService } from '../shipment.service';

import { ShippingMethod } from '../../shipping-methods/shipping-method.model';
import { ShippingMethodService } from '../../shipping-methods/shipping-method.service';

import { environment } from '../../../../environments/environment';

interface ShipmentOrder {
  id: number;
  orderId: string;
  customerName?: string;
  orderStatus?: string;
}

@Component({
  selector: 'app-create-shipment',
  templateUrl: './create-shipment.component.html',
  styleUrls: ['./create-shipment.component.css']
})
export class CreateShipmentComponent implements OnInit {

  submitting = false;
  loadingShippingMethods = false;
  loadingOrders = false;
  errorMessage = '';

  readonly statuses = [
    'Pending',
    'Packed',
    'Shipped',
    'Out For Delivery',
    'Delivered'
  ];

  shippingMethods: ShippingMethod[] = [];
  orders: ShipmentOrder[] = [];

  shipmentForm: Shipment = this.createInitialForm();

  constructor(
    private shipmentService: ShipmentService,
    private shippingMethodService: ShippingMethodService,
    private http: HttpClient,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadShippingMethods();
    this.loadOrders();
  }

  loadOrders(): void {
    this.loadingOrders = true;

    this.http
      .get<ShipmentOrder[]>(`${environment.apiBaseUrl}/orders/list`)
      .subscribe({
        next: (orders) => {
          this.orders = (orders || []).filter(
            (order) =>
              !!order?.id &&
              !!order?.orderId
          );

          this.loadingOrders = false;
        },
        error: () => {
          this.loadingOrders = false;
          this.errorMessage = 'Failed to load orders.';
        }
      });
  }

  loadShippingMethods(): void {
    this.loadingShippingMethods = true;

    this.shippingMethodService.getShippingMethods().subscribe({
      next: (shippingMethods) => {
        this.shippingMethods = (shippingMethods || []).filter(item =>
          this.isActiveShippingMethod(item)
        );

        this.loadingShippingMethods = false;
      },
      error: () => {
        this.loadingShippingMethods = false;
        this.errorMessage = 'Failed to load shipping methods.';
      }
    });
  }

  onSave(): void {

    this.errorMessage = '';

    const selectedStatus = (this.shipmentForm.shipmentStatus || '').trim();

    if (
      !this.shipmentForm.orderId ||
      !this.shipmentForm.shippingMethodId ||
      !selectedStatus
    ) {
      this.errorMessage =
        'Order, Shipping Method, and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: Shipment = {
      ...this.shipmentForm,

      orderId: Number(this.shipmentForm.orderId),

      shippingMethodId: Number(
        this.shipmentForm.shippingMethodId
      ),

      trackingNumber: (this.shipmentForm.trackingNumber || '').trim(),

      courierName: (this.shipmentForm.courierName || '').trim(),

      shipmentStatus: selectedStatus,

      status: selectedStatus,

      dispatchDate: this.normalizeDateTime(
        this.shipmentForm.dispatchDate || ''
      ),

      estimatedDeliveryDate: this.normalizeDateTime(
        this.shipmentForm.estimatedDeliveryDate || ''
      ),

      deliveredDate: this.normalizeDateTime(
        this.shipmentForm.deliveredDate || ''
      ),

      remarks: (this.shipmentForm.remarks || '').trim()
    };

    this.shipmentService.createShipment(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/shipments/list']);
      },

      error: (error) => {
        this.submitting = false;

        this.errorMessage =
          error?.error?.message ||
          'Failed to create shipment.';
      }
    });
  }

  onReset(): void {
    this.shipmentForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/shipments/list']);
  }

  getShippingMethodLabel(shippingMethod: ShippingMethod): string {
    return `${shippingMethod.name}${
      shippingMethod.courierName
        ? ' - ' + shippingMethod.courierName
        : ''
    }`;
  }

  getOrderLabel(order: ShipmentOrder): string {
    return `${order.orderId}${
      order.customerName ? ' - ' + order.customerName : ''
    }`;
  }

  private isActiveShippingMethod(
    shippingMethod: ShippingMethod
  ): boolean {
    return (
      (shippingMethod.status || '').trim().toUpperCase() ===
      'ACTIVE'
    );
  }

  private normalizeDateTime(value: string): string {
    return value ? value.trim() : '';
  }

  private createInitialForm(): Shipment {
    return {
      id: 0,
      orderId: 0,
      shippingMethodId: 0,
      trackingNumber: '',
      courierName: '',
      shipmentStatus: 'Pending',
      status: 'Pending',
      dispatchDate: '',
      estimatedDeliveryDate: '',
      deliveredDate: '',
      remarks: ''
    };
  }
}