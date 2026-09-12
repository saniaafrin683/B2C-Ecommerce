import { HttpErrorResponse } from '@angular/common/http';
import { Component } from '@angular/core';

import { Observable } from 'rxjs';

import { CartItem } from '../../core/models/cart-item.model';
import { CartService } from '../../core/services/cart.service';

@Component({
  selector: 'app-cart',
  templateUrl: './cart.component.html',
  styleUrls: ['./cart.component.css']
})
export class CartComponent {
  cartItems$: Observable<CartItem[]>;
  cartTotal$: Observable<number>;
  regularSubtotal$: Observable<number>;
  productDiscountTotal$: Observable<number>;
  actionErrorMessage = '';
  isUpdatingCart = false;

  constructor(private readonly cartService: CartService) {
    this.cartItems$ = this.cartService.getCartItems();
    this.cartTotal$ = this.cartService.getCartTotal();
    this.regularSubtotal$ = this.cartService.getRegularSubtotal();
    this.productDiscountTotal$ = this.cartService.getProductDiscountTotal();
    this.cartService.refreshCartStock();
  }

  decreaseQuantity(item: CartItem): void {
    this.runCartAction(this.cartService.updateQuantity(item.productId, item.quantity - 1, item.size));
  }

  increaseQuantity(item: CartItem): void {
    this.runCartAction(this.cartService.updateQuantity(item.productId, item.quantity + 1, item.size));
  }

  updateQuantity(item: CartItem, quantity: number): void {
    this.runCartAction(this.cartService.updateQuantity(item.productId, quantity, item.size));
  }

  removeItem(item: CartItem): void {
    this.runCartAction(this.cartService.removeFromCart(item.productId, item.size));
  }

  clearCart(): void {
    this.runCartAction(this.cartService.clearCart());
  }

  hasStockIssues(cartItems: CartItem[]): boolean {
    return cartItems.some((item) => item.stock <= 0 || item.quantity > item.stock);
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

  private runCartAction(request$: Observable<CartItem[]>): void {
    this.isUpdatingCart = true;
    this.actionErrorMessage = '';
    request$.subscribe({
      next: () => {
        this.isUpdatingCart = false;
      },
      error: (error: HttpErrorResponse) => {
        this.isUpdatingCart = false;
        this.actionErrorMessage = error.error?.message || 'Unable to update cart right now.';
      }
    });
  }
}
