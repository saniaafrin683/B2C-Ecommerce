import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { Product } from '../models/product.model';

@Injectable({
  providedIn: 'root'
})
export class WishlistService {
  private readonly fallbackImage = 'assets/images/category/default-product.png';
  private readonly storageKey = 'styleora_user_wishlist';
  private readonly wishlistItemsSubject = new BehaviorSubject<Product[]>(this.loadWishlistItems());

  addToWishlist(product: Product): void {
    const normalizedProduct = this.normalizeProduct(product);
    const wishlistItems = [...this.wishlistItemsSubject.value];
    if (wishlistItems.some((item) => item.id === normalizedProduct.id)) {
      return;
    }

    wishlistItems.push(normalizedProduct);
    this.setWishlistItems(wishlistItems);
  }

  removeFromWishlist(productId: number): void {
    const wishlistItems = this.wishlistItemsSubject.value.filter((item) => item.id !== productId);
    this.setWishlistItems(wishlistItems);
  }

  toggleWishlist(product: Product): boolean {
    if (this.isInWishlist(product.id)) {
      this.removeFromWishlist(product.id);
      return false;
    }

    this.addToWishlist(product);
    return true;
  }

  isInWishlist(productId: number): boolean {
    return this.wishlistItemsSubject.value.some((item) => item.id === productId);
  }

  getWishlistItems(): Observable<Product[]> {
    return this.wishlistItemsSubject.asObservable();
  }

  getWishlistCount(): Observable<number> {
    return this.wishlistItemsSubject.asObservable().pipe(
      map((items) => items.length)
    );
  }

  private loadWishlistItems(): Product[] {
    const storedItems = localStorage.getItem(this.storageKey);
    if (!storedItems) {
      return [];
    }

    try {
      const parsedItems = JSON.parse(storedItems) as unknown[];
      if (!Array.isArray(parsedItems)) {
        return [];
      }

      const normalizedItems = parsedItems
        .map((item) => this.normalizeProduct(item as Partial<Product>))
        .filter((item): item is Product => item.id > 0);

      // Keep localStorage consistent after normalizing legacy entries.
      localStorage.setItem(this.storageKey, JSON.stringify(normalizedItems));
      return normalizedItems;
    } catch {
      return [];
    }
  }

  private setWishlistItems(items: Product[]): void {
    const normalizedItems = items.map((item) => this.normalizeProduct(item));
    this.wishlistItemsSubject.next(normalizedItems);
    localStorage.setItem(this.storageKey, JSON.stringify(normalizedItems));
  }

  private normalizeProduct(product: Partial<Product>): Product {
    const id = Number(product?.id);
    const price = Number(product?.price);
    const stock = Number(product?.stock);

    return {
      id: Number.isFinite(id) ? id : 0,
      name: (product?.name || 'Unnamed product').trim(),
      price: Number.isFinite(price) ? price : 0,
      discount: Number(product?.discount) || 0,
      stock: Number.isFinite(stock) ? Math.max(0, Math.floor(stock)) : 0,
      imageUrl: (product?.imageUrl || this.fallbackImage).trim() || this.fallbackImage,
      category: (product?.category || 'General').trim(),
      subCategory: product?.subCategory || '',
      subcategory: product?.subcategory || '',
      gender: product?.gender || '',
      brand: product?.brand || '',
      description: product?.description || ''
    };
  }
}
