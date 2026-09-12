import { Injectable } from '@angular/core';
import { BehaviorSubject, forkJoin, Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';

import { CartItem } from '../models/cart-item.model';
import { Product } from '../models/product.model';
import { ProductService, ProductStockAdjustmentResponse } from './product.service';
import { ToastService } from './toast.service';

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private readonly storageKey = 'styleora_user_cart';
  private readonly cartItemsSubject = new BehaviorSubject<CartItem[]>(this.loadCartItems());

  constructor(
    private readonly productService: ProductService,
    private readonly toastService: ToastService
  ) {
    this.refreshCartStock();
  }

  getCartItems(): Observable<CartItem[]> {
    return this.cartItemsSubject.asObservable();
  }

  addToCart(product: Product, quantity = 1, size?: string): Observable<Product> {
    const normalizedQuantity = this.normalizeQuantity(quantity);
    const productStock = this.normalizeStock(product.stock);
    if (productStock <= 0 || normalizedQuantity <= 0) {
      return of(product);
    }

    const normalizedSize = size?.trim() || '';

    return this.productService.reserveStock(product.id, normalizedQuantity).pipe(
      map((response) => {
        const cartItems = [...this.cartItemsSubject.value];
        const existingIndex = this.findCartItemIndex(cartItems, product.id, normalizedSize);
        const reservedQuantity = normalizedQuantity;
        const maxQuantity = this.normalizeStock(response.stock) + reservedQuantity;

        if (existingIndex >= 0) {
          const existingItem = cartItems[existingIndex];
          const nextReservedQuantity = this.normalizeReservedQuantity(existingItem.reservedQuantity, existingItem.quantity) + reservedQuantity;
          const nextQuantity = existingItem.quantity + normalizedQuantity;
          cartItems[existingIndex] = {
            ...existingItem,
            quantity: nextQuantity,
            reservedQuantity: nextReservedQuantity,
            stock: this.normalizeStock(response.stock) + nextReservedQuantity,
            outOfStock: (this.normalizeStock(response.stock) + nextReservedQuantity) <= 0
          };
        } else {
          cartItems.push({
            productId: product.id,
            name: product.name,
            price: product.price,
            discount: this.normalizeDiscount(product.discount),
            imageUrl: product.imageUrl,
            size: normalizedSize || undefined,
            quantity: normalizedQuantity,
            stock: maxQuantity,
            reservedQuantity,
            outOfStock: maxQuantity <= 0
          });
        }

        this.setCartItems(cartItems);
        this.toastService.show(this.buildAddedToCartMessage(product));
        return { ...product, stock: this.normalizeStock(response.stock) };
      })
    );
  }

  removeFromCart(productId: number, size?: string): Observable<CartItem[]> {
    const cartItems = [...this.cartItemsSubject.value];
    const normalizedSize = size?.trim() || '';
    const existingIndex = this.findCartItemIndex(cartItems, productId, normalizedSize);

    if (existingIndex < 0) {
      return of(this.cartItemsSubject.value);
    }

    const existingItem = cartItems[existingIndex];
    const reservedQuantity = this.normalizeReservedQuantity(existingItem.reservedQuantity, existingItem.quantity);
    cartItems.splice(existingIndex, 1);

    if (reservedQuantity <= 0) {
      this.setCartItems(cartItems);
      return of(cartItems);
    }

    return this.productService.releaseStock(productId, reservedQuantity).pipe(
      map(() => {
        this.setCartItems(cartItems);
        return cartItems;
      })
    );
  }

  updateQuantity(productId: number, quantity: number, size?: string): Observable<CartItem[]> {
    const cartItems = [...this.cartItemsSubject.value];
    const normalizedSize = size?.trim() || '';
    const existingIndex = this.findCartItemIndex(cartItems, productId, normalizedSize);

    if (existingIndex < 0) {
      return of(this.cartItemsSubject.value);
    }

    const existingItem = cartItems[existingIndex];
    const nextQuantity = Math.max(0, Math.floor(quantity));
    if (nextQuantity <= 0) {
      return this.removeFromCart(productId, normalizedSize);
    }

    if (nextQuantity === existingItem.quantity) {
      return of(this.cartItemsSubject.value);
    }

    const currentReservedQuantity = this.normalizeReservedQuantity(existingItem.reservedQuantity, existingItem.quantity);
    const currentAvailableStock = Math.max(this.normalizeStock(existingItem.stock) - currentReservedQuantity, 0);
    const quantityDelta = nextQuantity - existingItem.quantity;

    if (quantityDelta > 0) {
      return this.productService.reserveStock(productId, quantityDelta).pipe(
        map((response) => {
          const nextReservedQuantity = currentReservedQuantity + quantityDelta;
          cartItems[existingIndex] = {
            ...existingItem,
            quantity: nextQuantity,
            reservedQuantity: nextReservedQuantity,
            stock: this.normalizeStock(response.stock) + nextReservedQuantity,
            outOfStock: (this.normalizeStock(response.stock) + nextReservedQuantity) <= 0
          };
          this.setCartItems(cartItems);
          return cartItems;
        })
      );
    }

    const releaseQuantity = Math.min(currentReservedQuantity, Math.abs(quantityDelta));
    const applyQuantityDecrease = (availableStock: number): CartItem[] => {
      const nextReservedQuantity = Math.max(currentReservedQuantity - releaseQuantity, 0);
      cartItems[existingIndex] = {
        ...existingItem,
        quantity: nextQuantity,
        reservedQuantity: nextReservedQuantity,
        stock: availableStock + nextReservedQuantity,
        outOfStock: (availableStock + nextReservedQuantity) <= 0
      };
      this.setCartItems(cartItems);
      return cartItems;
    };

    if (releaseQuantity <= 0) {
      return of(applyQuantityDecrease(currentAvailableStock));
    }

    return this.productService.releaseStock(productId, releaseQuantity).pipe(
      map((response) => applyQuantityDecrease(this.normalizeStock(response.stock)))
    );
  }

  clearCart(): Observable<CartItem[]> {
    const cartItems = [...this.cartItemsSubject.value];
    const releaseRequests = cartItems
      .map((item) => {
        const reservedQuantity = this.normalizeReservedQuantity(item.reservedQuantity, item.quantity);
        if (reservedQuantity <= 0) {
          return null;
        }

        return this.productService.releaseStock(item.productId, reservedQuantity);
      })
      .filter((request): request is Observable<ProductStockAdjustmentResponse> => request !== null);

    if (!releaseRequests.length) {
      this.setCartItems([]);
      return of([]);
    }

    return forkJoin(releaseRequests).pipe(
      map(() => {
        this.setCartItems([]);
        return [];
      })
    );
  }

  clearCartAfterCheckout(): void {
    this.setCartItems([]);
  }

  getCartCount(): Observable<number> {
    return this.cartItemsSubject.asObservable().pipe(
      map((items) => items.reduce((total, item) => total + item.quantity, 0))
    );
  }

  getCartTotal(): Observable<number> {
    return this.cartItemsSubject.asObservable().pipe(
      map((items) => items.reduce((total, item) => total + this.getLineDiscountedTotal(item), 0))
    );
  }

  getRegularSubtotal(): Observable<number> {
    return this.cartItemsSubject.asObservable().pipe(
      map((items) => items.reduce((total, item) => total + this.getLineRegularTotal(item), 0))
    );
  }

  getProductDiscountTotal(): Observable<number> {
    return this.cartItemsSubject.asObservable().pipe(
      map((items) => items.reduce((total, item) => total + this.getLineProductDiscountTotal(item), 0))
    );
  }

  hasStockIssues(): boolean {
    return this.cartItemsSubject.value.some((item) => item.stock <= 0 || item.quantity > item.stock);
  }

  refreshCartStock(): void {
    this.productService.getProducts().subscribe({
      next: (products) => {
        const stockMap = new Map<number, Product>((products || []).map((product) => [product.id, product]));
        const syncedItems = this.cartItemsSubject.value
          .map((item) => {
            const product = stockMap.get(item.productId);
            const availableStock = this.normalizeStock(product?.stock);
            const reservedQuantity = this.normalizeReservedQuantity(item.reservedQuantity, item.quantity);
            const stock = availableStock + reservedQuantity;
            return {
              ...item,
              price: typeof product?.price === 'number' ? product.price : item.price,
              discount: this.normalizeDiscount(product?.discount ?? item.discount),
              imageUrl: product?.imageUrl || item.imageUrl,
              reservedQuantity,
              stock,
              quantity: Math.min(item.quantity, Math.max(stock, 0)),
              outOfStock: stock <= 0
            };
          })
          .filter((item) => item.quantity > 0);

        this.setCartItems(syncedItems);
      }
    });
  }

  private loadCartItems(): CartItem[] {
    const storedCart = localStorage.getItem(this.storageKey);

    if (!storedCart) {
      return [];
    }

    try {
      return (JSON.parse(storedCart) as CartItem[]).map((item) => ({
        ...item,
        discount: this.normalizeDiscount(item.discount),
        reservedQuantity: this.normalizeReservedQuantity(item.reservedQuantity, item.quantity),
        stock: this.normalizeStock(item.stock),
        outOfStock: this.normalizeStock(item.stock) <= 0
      }));
    } catch {
      return [];
    }
  }

  private setCartItems(items: CartItem[]): void {
    this.cartItemsSubject.next(items);
    localStorage.setItem(this.storageKey, JSON.stringify(items));
  }

  private findCartItemIndex(items: CartItem[], productId: number, size: string): number {
    return items.findIndex((item) =>
      item.productId === productId &&
      ((item.size || '') === size)
    );
  }

  private normalizeQuantity(quantity: number | null | undefined): number {
    const normalizedQuantity = Number(quantity ?? 0);
    return Number.isFinite(normalizedQuantity) ? Math.max(0, Math.floor(normalizedQuantity)) : 0;
  }

  private normalizeStock(stock: number | null | undefined): number {
    const normalizedStock = Number(stock ?? 0);
    return Number.isFinite(normalizedStock) ? Math.max(0, Math.floor(normalizedStock)) : 0;
  }

  private normalizeReservedQuantity(reservedQuantity: number | null | undefined, quantity: number | null | undefined): number {
    const normalizedReservedQuantity = this.normalizeQuantity(reservedQuantity);
    const normalizedQuantity = this.normalizeQuantity(quantity);
    return Math.min(normalizedReservedQuantity, normalizedQuantity);
  }

  private normalizeDiscount(discount: number | null | undefined): number {
    const normalizedDiscount = Number(discount ?? 0);
    if (!Number.isFinite(normalizedDiscount)) {
      return 0;
    }

    return Math.min(Math.max(normalizedDiscount, 0), 100);
  }

  getDiscountedPrice(item: Pick<CartItem, 'price' | 'discount'>): number {
    const price = Number(item.price || 0);
    const discount = this.normalizeDiscount(item.discount);
    return Number((price * (1 - (discount / 100))).toFixed(2));
  }

  getLineRegularTotal(item: Pick<CartItem, 'price' | 'quantity'>): number {
    return Number(((item.price || 0) * (item.quantity || 0)).toFixed(2));
  }

  getLineDiscountedTotal(item: Pick<CartItem, 'price' | 'discount' | 'quantity'>): number {
    return Number((this.getDiscountedPrice(item) * (item.quantity || 0)).toFixed(2));
  }

  getLineProductDiscountTotal(item: Pick<CartItem, 'price' | 'discount' | 'quantity'>): number {
    return Number((this.getLineRegularTotal(item) - this.getLineDiscountedTotal(item)).toFixed(2));
  }

  private buildAddedToCartMessage(product: Product): string {
    const productName = (product?.name || '').trim();
    return productName ? `${productName} added to cart` : 'Product added to cart';
  }
}
