import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Shipment } from '../shipment.model';
import { ShipmentService } from '../shipment.service';
import { ShippingMethod } from '../../shipping-methods/shipping-method.model';
import { ShippingMethodService } from '../../shipping-methods/shipping-method.service';

@Component({
  selector: 'app-edit-shipment',
  templateUrl: './edit-shipment.component.html',
  styleUrls: ['./edit-shipment.component.css']
})
export class EditShipmentComponent implements OnInit {
  shipmentId!: number;
  loading = false;
  loadingShippingMethods = false;
  submitting = false;
  errorMessage = '';

  readonly statuses = ['Pending', 'Packed', 'Shipped', 'Out For Delivery', 'Delivered'];
  shippingMethods: ShippingMethod[] = [];
  shipmentForm: Shipment = this.createInitialForm();
  private initialSnapshot: Shipment = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private shipmentService: ShipmentService,
    private shippingMethodService: ShippingMethodService
  ) {}

  ngOnInit(): void {
    this.loadShippingMethods();

    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.shipmentId = +id;
        this.loadShipment();
      } else {
        this.router.navigate(['/shipments/list']);
      }
    });
  }

  loadShippingMethods(): void {
    this.loadingShippingMethods = true;
    this.shippingMethodService.getShippingMethods().subscribe({
      next: (shippingMethods) => {
        this.shippingMethods = (shippingMethods || []).filter(item => this.isActiveShippingMethod(item) || item.id === this.shipmentForm.shippingMethodId);
        this.loadingShippingMethods = false;
      },
      error: () => {
        this.loadingShippingMethods = false;
        this.errorMessage = 'Failed to load shipping methods.';
      }
    });
  }

  loadShipment(): void {
    this.loading = true;
    this.errorMessage = '';

    this.shipmentService.getShipmentById(this.shipmentId).subscribe({
      next: (shipment) => {
        this.shipmentForm = {
          ...shipment,
          shipmentStatus: shipment.shipmentStatus || shipment.status || 'Pending',
          status: shipment.shipmentStatus || shipment.status || 'Pending',
          dispatchDate: this.formatDateTimeForInput(shipment.dispatchDate || shipment.shippedDate || ''),
          estimatedDeliveryDate: this.formatDateTimeForInput(shipment.estimatedDeliveryDate || ''),
          deliveredDate: this.formatDateTimeForInput(shipment.deliveredDate || '')
        };
        this.initialSnapshot = { ...this.shipmentForm };
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load shipment.';
      }
    });
  }

  onSave(): void {
    this.errorMessage = '';

    const selectedStatus = (this.shipmentForm.shipmentStatus || '').trim();

    if (!this.shipmentForm.orderId || !this.shipmentForm.shippingMethodId || !selectedStatus) {
      this.errorMessage = 'Order ID, Shipping Method, and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: Shipment = {
      ...this.shipmentForm,
      orderId: Number(this.shipmentForm.orderId ?? 0),
      shippingMethodId: Number(this.shipmentForm.shippingMethodId ?? 0),
      trackingNumber: (this.shipmentForm.trackingNumber || '').trim(),
      courierName: (this.shipmentForm.courierName || '').trim(),
      shipmentStatus: selectedStatus,
      status: selectedStatus,
      dispatchDate: this.normalizeDateTime(this.shipmentForm.dispatchDate || this.shipmentForm.shippedDate || ''),
      estimatedDeliveryDate: this.normalizeDateTime(this.shipmentForm.estimatedDeliveryDate || ''),
      deliveredDate: this.normalizeDateTime(this.shipmentForm.deliveredDate || ''),
      remarks: (this.shipmentForm.remarks || '').trim()
    };

    this.shipmentService.updateShipment(this.shipmentId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/shipments/list'], { queryParams: { updated: 1 } });
      },
      error: (error) => {
        this.submitting = false;
        this.errorMessage = error?.error?.message || 'Failed to update shipment.';
      }
    });
  }

  onReset(): void {
    this.shipmentForm = { ...this.initialSnapshot };
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/shipments/list']);
  }

  getShippingMethodLabel(shippingMethod: ShippingMethod): string {
    return `${shippingMethod.name}${shippingMethod.courierName ? ' - ' + shippingMethod.courierName : ''}`;
  }

  private isActiveShippingMethod(shippingMethod: ShippingMethod): boolean {
    return (shippingMethod.status || '').trim().toUpperCase() === 'ACTIVE';
  }

  private formatDateTimeForInput(value: string): string {
    return value ? value.slice(0, 16) : '';
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
