import { Component, OnDestroy, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { CartItem, CartService, CartSummary } from '../../../shared/services/cart.service';

@Component({
  selector: 'app-cart',
  templateUrl: './cart.component.html',
  styleUrls: ['./cart.component.css']
})
export class CartComponent implements OnInit {
  cartItems: CartItem[] = [];
  summary: CartSummary = {
    subtotal: 0,
    discount: 0,
    tax: 0,
    shipping: 0,
    total: 0,
    itemCount: 0,
    totalQuantity: 0
  };
  private cartSubscription?: Subscription;

  constructor(
    private router: Router,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    this.cartSubscription = this.cartService.cartItems$.subscribe((items) => {
      this.cartItems = items;
      this.summary = this.cartService.getCartSummary();
    });
  }

  ngOnDestroy(): void {
    this.cartSubscription?.unsubscribe();
  }

  increaseQuantity(item: CartItem): void {
    this.cartService.updateQuantity(item.id, item.quantity + 1);
  }

  decreaseQuantity(item: CartItem): void {
    if (item.quantity <= 1) {
      return;
    }

    this.cartService.updateQuantity(item.id, item.quantity - 1);
  }

  removeItem(id: number): void {
    this.cartService.removeItem(id);
  }

  onClearCart(): void {
    this.cartService.clearCart();
  }

  continueShopping(): void {
    this.router.navigate(['/products/grid']);
  }

  getItemSubtotal(item: CartItem): number {
    return item.price * item.quantity;
  }

  get subtotal(): number {
    return this.summary.subtotal;
  }

  get discountAmount(): number {
    return this.summary.discount;
  }

  get shippingCharge(): number {
    return this.summary.shipping;
  }

  get taxAmount(): number {
    return this.summary.tax;
  }

  get grandTotal(): number {
    return this.summary.total;
  }
}
