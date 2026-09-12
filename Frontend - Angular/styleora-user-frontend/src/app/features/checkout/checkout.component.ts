import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable, firstValueFrom } from 'rxjs';

import { CartItem } from '../../core/models/cart-item.model';
import { AuthService, CustomerProfile } from '../../core/services/auth.service';
import { CartService } from '../../core/services/cart.service';
import { AppliedCoupon, CouponService } from '../../core/services/coupon.service';
import { CreateOrderPayload, OrderService } from '../../core/services/order.service';

interface CheckoutFormData {
  name: string;
  email: string;
  phone: string;
  address: string;
  paymentMethod: string;
  senderNumber: string;
  transactionId: string;
}

@Component({
  selector: 'app-checkout',
  templateUrl: './checkout.component.html',
  styleUrls: ['./checkout.component.css']
})
export class CheckoutComponent implements OnInit {
  readonly paymentOptions = ['Cash On Delivery', 'bKash', 'Nagad', 'Rocket'];

  cartItems$: Observable<CartItem[]>;
  cartTotal$: Observable<number>;
  regularSubtotal$: Observable<number>;
  productDiscountTotal$: Observable<number>;

  errorMessage = '';
  couponCode = '';
  couponErrorMessage = '';
  couponSuccessMessage = '';
  isApplyingCoupon = false;
  isSubmitting = false;
  appliedCoupon: AppliedCoupon | null = null;
  authenticatedCustomer: CustomerProfile | null = null;

  formData: CheckoutFormData = {
    name: '',
    email: '',
    phone: '',
    address: '',
    paymentMethod: 'Cash On Delivery',
    senderNumber: '',
    transactionId: ''
  };

  constructor(
    private readonly authService: AuthService,
    private readonly cartService: CartService,
    private readonly couponService: CouponService,
    private readonly orderService: OrderService,
    private readonly router: Router,
    private readonly cdr: ChangeDetectorRef
  ) {
    this.cartItems$ = this.cartService.getCartItems();
    this.cartTotal$ = this.cartService.getCartTotal();
    this.regularSubtotal$ = this.cartService.getRegularSubtotal();
    this.productDiscountTotal$ = this.cartService.getProductDiscountTotal();
    this.authenticatedCustomer = this.authService.getCustomerSnapshot();
    this.formData = this.buildCheckoutProfile(this.authenticatedCustomer);
  }

  ngOnInit(): void {
    if (!this.authService.isAuthenticated()) {
      void this.router.navigate(['/login']);
      return;
    }

    this.authService.loadProfile().subscribe({
      next: (customer) => {
        this.authenticatedCustomer = customer;
        this.formData = this.buildCheckoutProfile(customer);
      },
      error: () => {
        this.errorMessage = 'Unable to load your checkout profile. Please sign in again.';
      }
    });
  }

  isMobilePaymentSelected(): boolean {
    return ['bKash', 'Nagad', 'Rocket'].includes(this.formData.paymentMethod);
  }

  onPaymentMethodChange(): void {
    if (!this.isMobilePaymentSelected()) {
      this.formData.senderNumber = '';
      this.formData.transactionId = '';
    }
  }

  async placeOrder(form: NgForm, cartItems: CartItem[]): Promise<void> {
    if (form.invalid || !cartItems.length) {
      form.control.markAllAsTouched();
      return;
    }

    if (this.isMobilePaymentSelected()) {
      if (!this.formData.senderNumber.trim() || !this.formData.transactionId.trim()) {
        this.errorMessage = 'Sender number and transaction ID are required for mobile payment.';
        return;
      }
    }

    this.cartService.refreshCartStock();

    if (cartItems.some((item) => item.stock <= 0 || item.quantity > item.stock)) {
      this.errorMessage = 'One or more items in your cart are out of stock or exceed available stock.';
      return;
    }

    this.errorMessage = '';
    this.isSubmitting = true;

    try {
      const payload = this.buildOrderPayload(cartItems);
      const createdOrder = await firstValueFrom(this.orderService.createOrder(payload));

      this.cartService.clearCartAfterCheckout();
      this.removeCoupon();
      form.resetForm(this.buildCheckoutProfile(this.authenticatedCustomer || this.authService.getCustomerSnapshot()));

      await this.router.navigate(['/order-success'], {
        queryParams: {
          orderId: createdOrder.orderId || payload.orderId,
          orderDbId: createdOrder.id
        }
      });
    } catch (error) {
      if (error instanceof HttpErrorResponse) {
        this.errorMessage =
          typeof error.error === 'string'
            ? error.error
            : error.error?.message || error.message || 'Unable to place order. Please try again.';
      } else {
        this.errorMessage = 'Unable to place order. Please try again.';
      }
    } finally {
      this.isSubmitting = false;
    }
  }

  async applyCoupon(): Promise<void> {
    const normalizedCouponCode = this.couponCode.trim();
    const [subtotal, cartItems] = await Promise.all([
      firstValueFrom(this.cartService.getCartTotal()),
      firstValueFrom(this.cartService.getCartItems())
    ]);

    this.couponErrorMessage = '';
    this.couponSuccessMessage = '';

    if (!normalizedCouponCode) {
      this.appliedCoupon = null;
      this.couponErrorMessage = 'Enter a coupon code to apply.';
      this.cdr.detectChanges();
      return;
    }

    if (!subtotal || subtotal <= 0) {
      this.appliedCoupon = null;
      this.couponErrorMessage = 'Add items to your cart before applying a coupon.';
      this.cdr.detectChanges();
      return;
    }

    this.isApplyingCoupon = true;

    try {
      this.appliedCoupon = await firstValueFrom(
        this.couponService.applyCoupon({
          couponCode: normalizedCouponCode,
          subtotal,
          orderItems: cartItems.map((item) => ({
            productId: item.productId,
            quantity: item.quantity
          }))
        })
      );

      this.couponCode = this.appliedCoupon.couponCode;
      this.couponSuccessMessage = this.appliedCoupon.message || 'Coupon applied successfully.';
      this.cdr.detectChanges();
    } catch (error) {
      this.appliedCoupon = null;
      this.couponSuccessMessage = '';

      if (error instanceof HttpErrorResponse) {
        this.couponErrorMessage =
          typeof error.error === 'string'
            ? error.error
            : error.error?.message || error.message || 'Unable to apply coupon.';
      } else {
        this.couponErrorMessage = 'Unable to apply coupon.';
      }
      this.cdr.detectChanges();
    } finally {
      this.isApplyingCoupon = false;
    }
  }

  removeCoupon(): void {
    this.couponCode = '';
    this.appliedCoupon = null;
    this.couponErrorMessage = '';
    this.couponSuccessMessage = '';
    this.cdr.detectChanges();
  }

  hasStockIssues(cartItems: CartItem[]): boolean {
    return cartItems.some((item) => item.stock <= 0 || item.quantity > item.stock);
  }

  getDiscountAmount(): number {
    return Number((this.appliedCoupon?.discountAmount || 0).toFixed(2));
  }

  getFinalTotal(cartSubtotal: number): number {
    const subtotal = Number((cartSubtotal || 0).toFixed(2));
    return Number((subtotal - this.getDiscountAmount()).toFixed(2));
  }

  getDiscountedPrice(item: CartItem): number {
    return this.cartService.getDiscountedPrice(item);
  }

  getLineRegularTotal(item: CartItem): number {
    return this.cartService.getLineRegularTotal(item);
  }

  getLineDiscountedTotal(item: CartItem): number {
    return this.cartService.getLineDiscountedTotal(item);
  }

  getLineProductDiscountTotal(item: CartItem): number {
    return this.cartService.getLineProductDiscountTotal(item);
  }

  private generateOrderId(): string {
    return `ORD-${Date.now().toString().slice(-8)}`;
  }

  private getTodayDate(): string {
    return new Date().toISOString().split('T')[0];
  }

  private getItemSubtotal(item: CartItem): number {
    return this.cartService.getLineDiscountedTotal(item);
  }

  private getRegularSubtotal(cartItems: CartItem[]): number {
    return Number(
      cartItems.reduce((total, item) => total + this.cartService.getLineRegularTotal(item), 0).toFixed(2)
    );
  }

  private getProductDiscountTotal(cartItems: CartItem[]): number {
    return Number(
      cartItems.reduce((total, item) => total + this.cartService.getLineProductDiscountTotal(item), 0).toFixed(2)
    );
  }

  private getSubtotalAfterProductDiscount(cartItems: CartItem[]): number {
    return Number(
      cartItems.reduce((total, item) => total + this.cartService.getLineDiscountedTotal(item), 0).toFixed(2)
    );
  }

  private buildOrderPayload(cartItems: CartItem[]): CreateOrderPayload {
    const currentCustomer = this.authenticatedCustomer || this.authService.getCustomerSnapshot();

    // Use backend-validated values when coupon is applied, otherwise calculate locally
    let regularSubtotal: number;
    let productDiscountTotal: number;
    let subtotalAfterProductDiscount: number;
    let couponDiscount: number;
    let finalTotal: number;

    if (this.appliedCoupon) {
      // Use backend-calculated values from coupon response
      regularSubtotal = Number((this.appliedCoupon.regularSubtotal || 0).toFixed(2));
      productDiscountTotal = Number((this.appliedCoupon.productDiscountTotal || 0).toFixed(2));
      subtotalAfterProductDiscount = Number((this.appliedCoupon.subtotalAfterProductDiscount || 0).toFixed(2));
      couponDiscount = Number((this.appliedCoupon.discountAmount || 0).toFixed(2));
      finalTotal = Number((this.appliedCoupon.finalTotal || 0).toFixed(2));
    } else {
      // Calculate locally when no coupon is applied
      regularSubtotal = this.getRegularSubtotal(cartItems);
      productDiscountTotal = this.getProductDiscountTotal(cartItems);
      subtotalAfterProductDiscount = this.getSubtotalAfterProductDiscount(cartItems);
      couponDiscount = 0;
      finalTotal = subtotalAfterProductDiscount;
    }

    return {
      orderId: this.generateOrderId(),
      createdAt: this.getTodayDate(),

      customerName: currentCustomer?.fullName?.trim() || this.formData.name.trim(),
      customerEmail: currentCustomer?.email?.trim() || this.formData.email.trim(),
      customerPhone: this.formData.phone.trim(),

      shippingAddress: this.formData.address.trim(),
      billingAddress: this.formData.address.trim(),

      priority: 'Medium',

      subtotal: subtotalAfterProductDiscount,
      regularSubtotal,
      productDiscountTotal,
      subtotalAfterProductDiscount,

      tax: 0,
      discount: couponDiscount,
      couponDiscount,
      shippingCost: 0,
      couponCode: this.appliedCoupon?.couponCode || '',
      totalAmount: finalTotal,

      paymentMethod: this.formData.paymentMethod,
      paymentStatus: 'Pending',

      paymentSenderNumber: this.formData.senderNumber.trim(),
      paymentTransactionId: this.formData.transactionId.trim(),

      orderStatus: 'Pending',

      orderItems: cartItems.map((item) => ({
        productId: item.productId,
        productName: item.name,
        productImage: item.imageUrl,
        size: item.size || '',
        color: '',

        originalUnitPrice: Number(item.price.toFixed(2)),
        discountedUnitPrice: this.getDiscountedPrice(item),
        productDiscountRate: Number((item.discount || 0).toFixed(2)),
        productDiscountAmount: Number((item.price - this.getDiscountedPrice(item)).toFixed(2)),

        originalLineTotal: this.getLineRegularTotal(item),
        productDiscountLineTotal: this.getLineProductDiscountTotal(item),
        unitPrice: this.getDiscountedPrice(item),
        quantity: item.quantity,
        reservedQuantity: item.reservedQuantity || 0,
        lineTotal: this.getItemSubtotal(item)
      }))
    };
  }

  private buildCheckoutProfile(
    customer: { fullName?: string; email?: string; phone?: string; address?: string } | null
  ): CheckoutFormData {
    return {
      name: customer?.fullName?.trim() || '',
      email: customer?.email?.trim() || '',
      phone: customer?.phone?.trim() || '',
      address: customer?.address?.trim() || '',
      paymentMethod: this.formData.paymentMethod || 'Cash On Delivery',
      senderNumber: '',
      transactionId: ''
    };
  }
}