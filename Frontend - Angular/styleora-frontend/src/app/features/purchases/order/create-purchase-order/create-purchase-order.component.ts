import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { PurchaseOrder, PurchaseOrderLineItem } from '../../purchase-order.model';
import { PurchaseOrderService } from '../../purchase-order.service';

@Component({
  selector: 'app-create-purchase-order',
  templateUrl: './create-purchase-order.component.html',
  styleUrls: ['./create-purchase-order.component.css']
})
export class CreatePurchaseOrderComponent {
  orderForm: PurchaseOrder = this.createInitialForm();
  itemsInput = '';
  submitting = false;
  errorMessage = '';

  readonly orderStatuses = ['Pending', 'Approved', 'Received', 'Completed', 'Cancelled'];
  readonly paymentStatuses = ['Pending', 'Paid', 'Partial', 'Refunded'];
  readonly paymentMethods = ['Credit Card', 'Bank Transfer', 'Cash on Delivery', 'PayPal'];

  constructor(
    private purchaseOrderService: PurchaseOrderService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.orderForm.purchaseOrderId.trim() ||
        !this.orderForm.supplierName.trim() ||
        !this.orderForm.orderDate ||
        !this.orderForm.orderStatus ||
        !this.orderForm.paymentStatus ||
        !this.orderForm.totalAmount) {
      this.errorMessage = 'Purchase Order ID, Supplier Name, Order Date, Order Status, Payment Status, and Total Amount are required.';
      return;
    }

    const parsedItems = this.parseItemsInput(this.itemsInput);
    if (this.itemsInput.trim() && parsedItems.length === 0) {
      this.errorMessage = 'Items must be valid JSON array or plain text lines.';
      return;
    }

    this.submitting = true;

    const payload: PurchaseOrder = {
      ...this.orderForm,
      purchaseOrderId: this.orderForm.purchaseOrderId.trim(),
      supplierName: this.orderForm.supplierName.trim(),
      supplierEmail: (this.orderForm.supplierEmail || '').trim(),
      supplierPhone: (this.orderForm.supplierPhone || '').trim(),
      supplierAddress: (this.orderForm.supplierAddress || '').trim(),
      items: parsedItems,
      subtotal: Number(this.orderForm.subtotal ?? 0),
      discount: Number(this.orderForm.discount ?? 0),
      tax: Number(this.orderForm.tax ?? 0),
      shippingCost: Number(this.orderForm.shippingCost ?? 0),
      totalAmount: Number(this.orderForm.totalAmount ?? 0),
      paidAmount: Number(this.orderForm.paidAmount ?? 0),
      dueAmount: Number(this.orderForm.dueAmount ?? 0),
      notes: (this.orderForm.notes || '').trim()
    };

    this.purchaseOrderService.createPurchaseOrder(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/purchases/order']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create purchase order.';
      }
    });
  }

  onReset(): void {
    this.orderForm = this.createInitialForm();
    this.itemsInput = '';
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/purchases/order']);
  }

  goBack(): void {
    this.router.navigate(['/purchases/order']);
  }

  private createInitialForm(): PurchaseOrder {
    return {
      id: 0,
      purchaseOrderId: '',
      supplierName: '',
      supplierEmail: '',
      supplierPhone: '',
      supplierAddress: '',
      orderDate: '',
      expectedDeliveryDate: '',
      orderStatus: 'Pending',
      paymentStatus: 'Pending',
      paymentMethod: 'Credit Card',
      items: [],
      subtotal: 0,
      discount: 0,
      tax: 0,
      shippingCost: 0,
      totalAmount: 0,
      paidAmount: 0,
      dueAmount: 0,
      notes: ''
    };
  }

  private parseItemsInput(value: string): PurchaseOrderLineItem[] {
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      return [];
    }

    try {
      const parsedValue = JSON.parse(trimmedValue);
      if (Array.isArray(parsedValue)) {
        return parsedValue.map((item) => ({
          product: item?.product || item?.name || '',
          sku: item?.sku || '',
          quantity: Number(item?.quantity ?? 0),
          unitCost: Number(item?.unitCost ?? 0),
          discount: Number(item?.discount ?? 0),
          tax: Number(item?.tax ?? 0),
          total: Number(item?.total ?? 0)
        }));
      }
    } catch {
      const lines = trimmedValue.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
      if (!lines.length) {
        return [];
      }

      return lines.map((line) => ({
        product: line,
        sku: '',
        quantity: 1,
        unitCost: 0,
        discount: 0,
        tax: 0,
        total: 0
      }));
    }

    return [];
  }
}
