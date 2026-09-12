import { HttpErrorResponse } from '@angular/common/http';
import { Component, OnDestroy } from '@angular/core';
import { Observable } from 'rxjs';

import { CartItem } from '../../core/models/cart-item.model';
import { Product } from '../../core/models/product.model';
import { CartService } from '../../core/services/cart.service';
import { WishlistService } from '../../core/services/wishlist.service';

@Component({
  selector: 'app-wishlist',
  templateUrl: './wishlist.component.html',
  styleUrls: ['./wishlist.component.css']
})
export class WishlistComponent implements OnDestroy {
  readonly fallbackImage = 'assets/images/category/default-product.png';
  wishlistItems$: Observable<Product[]>;
  cartItems$: Observable<CartItem[]>;
  toastMessage = '';
  private readonly cartProductIds = new Set<number>();
  private toastTimeoutId: ReturnType<typeof setTimeout> | null = null;
  private readonly cartItemsSubscription = this.cartService.getCartItems().subscribe((items) => {
    this.cartProductIds.clear();
    items.forEach((item) => this.cartProductIds.add(item.productId));
  });

  constructor(
    private readonly wishlistService: WishlistService,
    private readonly cartService: CartService
  ) {
    this.wishlistItems$ = this.wishlistService.getWishlistItems();
    this.cartItems$ = this.cartService.getCartItems();
  }

  ngOnDestroy(): void {
    this.cartItemsSubscription.unsubscribe();
    if (this.toastTimeoutId) {
      clearTimeout(this.toastTimeoutId);
    }
  }

  removeFromWishlist(productId: number): void {
    this.wishlistService.removeFromWishlist(productId);
  }

  addToCart(product: Product): void {
    if (this.isInCartById(product.id)) {
      return;
    }

    this.cartService.addToCart(product).subscribe({
      next: () => {
        this.wishlistService.removeFromWishlist(product.id);
        this.showToast('Added to cart');
      },
      error: (error: HttpErrorResponse) => {
        this.showToast(error.error?.message || 'Unable to add to cart');
      }
    });
  }

  getProductImage(product: Product): string {
    const imageUrl = product?.imageUrl?.trim();
    return imageUrl || this.fallbackImage;
  }

  getProductPrice(product: Product): number {
    const price = Number(product?.price);
    return Number.isFinite(price) ? price : 0;
  }

  isProductInCart(productId: number, cartItems: CartItem[]): boolean {
    return this.cartProductIds.has(productId) || cartItems.some((item) => item.productId === productId);
  }

  private isInCartById(productId: number): boolean {
    return this.cartProductIds.has(productId);
  }

  private showToast(message: string): void {
    this.toastMessage = message;

    if (this.toastTimeoutId) {
      clearTimeout(this.toastTimeoutId);
    }

    this.toastTimeoutId = setTimeout(() => {
      this.toastMessage = '';
      this.toastTimeoutId = null;
    }, 1800);
  }
}
