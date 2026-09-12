import { HttpErrorResponse } from '@angular/common/http';
import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';

import { CartService } from '../../../core/services/cart.service';
import { Product } from '../../../core/models/product.model';
import { WishlistService } from '../../../core/services/wishlist.service';

@Component({
  selector: 'app-product-card',
  templateUrl: './product-card.component.html',
  styleUrls: ['./product-card.component.css']
})
export class ProductCardComponent implements OnChanges {
  @Input() product: Product | null = null;
  @Input() variant: 'default' | 'home' = 'default';

  addToCartMessage = '';
  addToCartErrorMessage = '';
  isWishlisted = false;
  adding = false;

  constructor(
    private readonly cartService: CartService,
    private readonly wishlistService: WishlistService
  ) {}

  ngOnChanges(_: SimpleChanges): void {
    this.syncWishlistState();
  }

  addToCart(): void {
    if (!this.product || this.adding) {
      return;
    }

    if (this.availableStock <= 0) {
      this.addToCartErrorMessage = 'Out of Stock';
      return;
    }

    this.adding = true;
    this.addToCartMessage = '';
    this.addToCartErrorMessage = '';

    this.cartService.addToCart(this.product).subscribe({
      next: (updatedProduct) => {
        this.product = updatedProduct;
        this.addToCartMessage = 'Added to cart';
        setTimeout(() => {
          this.adding = false;
          this.addToCartMessage = '';
        }, 1200);
      },
      error: (error: HttpErrorResponse) => {
        this.adding = false;
        this.addToCartErrorMessage = error.error?.message || 'Unable to add this product to cart.';
      }
    });
  }

  toggleWishlist(): void {
    if (!this.product) {
      return;
    }

    this.isWishlisted = this.wishlistService.toggleWishlist(this.product);
  }

  get productSubCategory(): string {
    return this.product?.subCategory || this.product?.subcategory || '';
  }

  get productImageUrl(): string {
    return this.product?.imageUrl || 'assets/images/category/default-product.png';
  }

  get availableStock(): number {
    const stockValue = Number(this.product?.stock ?? 0);
    return Number.isFinite(stockValue) ? Math.max(0, Math.floor(stockValue)) : 0;
  }

  get discountedPrice(): number {
    if (!this.product) {
      return 0;
    }

    const price = Number(this.product.price || 0);
    const discount = Number(this.product.discount || 0);

    if (discount <= 0) {
      return price;
    }

    return Math.max(price - (price * discount) / 100, 0);
  }

  get hasDiscount(): boolean {
    return Number(this.product?.discount || 0) > 0;
  }

  get stockTone(): 'in-stock' | 'low-stock' | 'out-of-stock' {
    if (this.availableStock <= 0) {
      return 'out-of-stock';
    }

    if (this.availableStock <= 5) {
      return 'low-stock';
    }

    return 'in-stock';
  }

  get stockLabel(): string {
    if (this.availableStock <= 0) {
      return 'Out of Stock';
    }

    if (this.availableStock <= 5) {
      return `Low Stock: ${this.availableStock}`;
    }

    return `In Stock: ${this.availableStock}`;
  }

  private syncWishlistState(): void {
    if (!this.product) {
      this.isWishlisted = false;
      return;
    }

    this.isWishlisted = this.wishlistService.isInWishlist(this.product.id);
  }
}
