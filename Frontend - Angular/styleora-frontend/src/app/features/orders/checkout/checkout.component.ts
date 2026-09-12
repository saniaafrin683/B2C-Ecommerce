import { Component, OnDestroy, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { finalize, switchMap } from 'rxjs/operators';
import { Order } from '../order.model';
import { OrdersService } from '../orders.service';
import { InvoiceService } from '../../invoices/invoice.service';
import { SettingsService } from '../../../core/services/settings.service';
import { CartItem, CartService, CartSummary } from '../../../shared/services/cart.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

interface CheckoutFormState {
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  shippingAddress: string;
  billingAddress: string;
  paymentMethod: string;
  paymentStatus: string;
  priority: string;
  orderStatus: string;
  trackingNumber: string;
}

@Component({
  selector: 'app-checkout',
  templateUrl: './checkout.component.html',
  styleUrls: ['./checkout.component.css']
})
export class CheckoutComponent implements OnInit, OnDestroy {
  checkoutItems: CartItem[] = [];
  summary: CartSummary = {
    subtotal: 0,
    discount: 0,
    tax: 0,
    shipping: 0,
    total: 0,
    itemCount: 0,
    totalQuantity: 0
  };
  form: CheckoutFormState = this.createInitialForm();
  submitting = false;
  errorMessage = '';

  readonly paymentMethods = ['PayPal', 'Credit Card', 'Cash on Delivery', 'Bank Transfer'];
  readonly paymentStatuses = ['Pending', 'Paid', 'Unpaid', 'Refunded'];
  readonly priorities = ['High', 'Medium', 'Low'];
  readonly orderStatuses = ['Pending', 'Confirmed', 'In Progress', 'Shipped', 'Delivered', 'Cancelled'];
  private cartSubscription?: Subscription;
  constructor(
    private ordersService: OrdersService,
    private invoiceService: InvoiceService,
    private settingsService: SettingsService,
    private router: Router,
    private cartService: CartService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.cartSubscription = this.cartService.cartItems$.subscribe((items) => {
      this.checkoutItems = items;
      this.summary = this.cartService.getCartSummary();
    });
  }

  ngOnDestroy(): void {
    this.cartSubscription?.unsubscribe();
  }

  createInitialForm(): CheckoutFormState {
    return {
      customerName: '',
      customerEmail: '',
      customerPhone: '',
      shippingAddress: '',
      billingAddress: '',
      paymentMethod: 'Credit Card',
      paymentStatus: 'Pending',
      priority: 'Medium',
      orderStatus: 'Pending',
      trackingNumber: ''
    };
  }

  get subtotal(): number {
    return this.summary.subtotal;
  }

  get tax(): number {
    return this.summary.tax;
  }

  get discount(): number {
    return this.summary.discount;
  }

  get shippingCost(): number {
    return this.summary.shipping;
  }

  get totalAmount(): number {
    return this.summary.total;
  }

  get totalItems(): number {
    return this.summary.totalQuantity;
  }

  getItemSubtotal(item: CartItem): number {
    return item.price * item.quantity;
  }

  generateOrderId(): string {
    return `${this.settingsService.getOrderPrefix()}-${Date.now().toString().slice(-8)}`;
  }

  getTodayDate(): string {
    return new Date().toISOString().split('T')[0];
  }

  onPlaceOrder(): void {
    this.errorMessage = '';

    if (!this.form.customerName.trim() || !this.form.customerEmail.trim() || !this.form.customerPhone.trim()) {
      this.errorMessage = 'Customer name, email, and phone are required.';
      return;
    }

    if (!this.form.shippingAddress.trim() || !this.form.billingAddress.trim()) {
      this.errorMessage = 'Shipping and billing address are required.';
      return;
    }

    if (!this.checkoutItems.length) {
      this.errorMessage = 'Checkout items are empty.';
      return;
    }

    this.submitting = true;
    this.loadingService.show();

    const payload: Order = {
      orderId: this.generateOrderId(),
      createdAt: this.getTodayDate(),
      customerName: this.form.customerName.trim(),
      customerEmail: this.form.customerEmail.trim(),
      customerPhone: this.form.customerPhone.trim(),
      shippingAddress: this.form.shippingAddress.trim(),
      billingAddress: this.form.billingAddress.trim(),
      priority: this.form.priority,
      subtotal: Number(this.subtotal.toFixed(2)),
      tax: Number(this.tax.toFixed(2)),
      discount: Number(this.discount.toFixed(2)),
      shippingCost: Number(this.shippingCost.toFixed(2)),
      totalAmount: Number(this.totalAmount.toFixed(2)),
      paymentMethod: this.form.paymentMethod,
      paymentStatus: this.form.paymentStatus,
      items: this.totalItems,
      quantity: this.totalItems,
      deliveryNumber: this.form.customerPhone.trim(),
      trackingNumber: this.form.trackingNumber.trim(),
      orderItems: this.checkoutItems.map((item) => ({
        productName: item.name,
        productImage: item.imageUrl,
        size: '',
        color: '',
        unitPrice: Number(item.price.toFixed(2)),
        quantity: item.quantity,
        lineTotal: Number(this.getItemSubtotal(item).toFixed(2))
      })),
      orderStatus: this.form.orderStatus
    };

    this.ordersService.createOrder(payload).pipe(
      switchMap((createdOrder) => {
        if (!createdOrder?.id) {
          throw new Error('Created order not found for invoice generation.');
        }

        return this.invoiceService.createInvoice(
          this.invoiceService.buildInvoiceFromOrder(createdOrder, Number(createdOrder.id))
        );
      }),
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.cartService.clearCart();
        this.notificationService.showSuccess('Order placed successfully.');
        this.router.navigate(['/orders/list']);
      },
      error: () => {
        this.errorMessage = 'Failed to place order or generate invoice.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onReset(): void {
    this.form = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/orders/list']);
  }
}
