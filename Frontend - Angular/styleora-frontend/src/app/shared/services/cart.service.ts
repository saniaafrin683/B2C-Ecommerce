import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { Product } from '../../features/products/product.model';
import { Category } from '../../features/category/category.model';
import { CATEGORY_CACHE_KEY } from '../../features/category/category.service';

export interface CartItem {
  id: number;
  name: string;
  price: number;
  imageUrl: string;
  quantity: number;
  category?: string;
  brand?: string;
  discountRate?: number;
  taxRate?: number;
}

export interface CartSummary {
  subtotal: number;
  discount: number;
  tax: number;
  shipping: number;
  total: number;
  itemCount: number;
  totalQuantity: number;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private readonly storageKey = 'styleora_admin_cart';
  private readonly defaultProductImage =
    'data:image/svg+xml;utf8,' +
    encodeURIComponent(
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480">
        <rect width="640" height="480" rx="28" fill="#f8fafc"/>
        <rect x="48" y="48" width="544" height="384" rx="24" fill="#e2e8f0"/>
        <path d="M180 320l72-88 64 76 92-120 88 132H180z" fill="#94a3b8"/>
        <circle cx="250" cy="176" r="34" fill="#cbd5e1"/>
        <text x="50%" y="86%" text-anchor="middle" font-family="Arial, sans-serif" font-size="28" fill="#475569">
          No image available
        </text>
      </svg>`
    );
  private readonly cartItemsSubject = new BehaviorSubject<CartItem[]>(this.readCartItems());

  readonly cartItems$ = this.cartItemsSubject.asObservable();

  getCartItems(): CartItem[] {
    return [...this.cartItemsSubject.value];
  }

  addToCart(product: Product): void {
    if (product.id === undefined || product.id === null) {
      return;
    }

    const cartItems = this.getCartItems();
    const existingItem = cartItems.find((item) => item.id === product.id);

    if (existingItem) {
      existingItem.quantity += 1;
    } else {
      cartItems.push({
        id: product.id,
        name: product.name,
        price: Number(product.price || 0),
        imageUrl: this.getImage(product),
        quantity: 1,
        category: product.category || '',
        brand: product.brand || '',
        discountRate: Number(product.discount || 0),
        taxRate: Number(product.tax || 0)
      });
    }

    this.persistCart(cartItems);
  }

  updateQuantity(productId: number, quantity: number): void {
    const safeQuantity = Math.max(1, Number(quantity || 1));
    const updatedItems = this.getCartItems().map((item) =>
      item.id === productId ? { ...item, quantity: safeQuantity } : item
    );

    this.persistCart(updatedItems);
  }

  removeItem(productId: number): void {
    const updatedItems = this.getCartItems().filter((item) => item.id !== productId);
    this.persistCart(updatedItems);
  }

  clearCart(): void {
    this.persistCart([]);
  }

  getCartSummary(): CartSummary {
    const cartItems = this.getCartItems();

    const subtotal = cartItems.reduce(
      (sum, item) => sum + (item.price * item.quantity),
      0
    );

    const discount = cartItems.reduce(
      (sum, item) => sum + this.getItemDiscount(item),
      0
    );

    const tax = cartItems.reduce(
      (sum, item) => sum + this.getItemTax(item),
      0
    );

    const shipping = cartItems.length ? 0 : 0;
    const total = subtotal - discount + tax + shipping;
    const totalQuantity = cartItems.reduce((sum, item) => sum + item.quantity, 0);

    return {
      subtotal: Number(subtotal.toFixed(2)),
      discount: Number(discount.toFixed(2)),
      tax: Number(tax.toFixed(2)),
      shipping: Number(shipping.toFixed(2)),
      total: Number(total.toFixed(2)),
      itemCount: cartItems.length,
      totalQuantity
    };
  }

  private getImage(product: Product): string {
    if (product.imageUrl && product.imageUrl.trim() !== '') {
      return product.imageUrl;
    }

    const categoryImage = this.getCategoryImage(product.category);
    if (categoryImage) {
      return categoryImage;
    }

    return this.getFallbackImageByCategory(product.category);
  }

  private getCategoryImage(category: string | null | undefined): string {
    const key = this.normalizeCategoryName(category);
    if (!key || !this.isBrowser()) {
      return '';
    }

    const matchedCategory = this.readCachedCategories().find((item) =>
      this.normalizeCategoryName(item.categoryTitle) === key && !!(item.imageUrl || '').trim()
    );

    return matchedCategory?.imageUrl?.trim() || '';
  }

  private readCachedCategories(): Category[] {
    const rawValue = localStorage.getItem(CATEGORY_CACHE_KEY);
    if (!rawValue) {
      return [];
    }

    try {
      const parsed = JSON.parse(rawValue);
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      console.error('Failed to parse cached categories in cart service', error);
      return [];
    }
  }

  private normalizeCategoryName(value: string | null | undefined): string {
    return (value || '').trim().toLowerCase();
  }

  private getFallbackImageByCategory(category: string | null | undefined): string {
    return this.defaultProductImage;
  }

  private getItemDiscount(item: CartItem): number {
    const discountRate = Number(item.discountRate || 0);
    return item.price * item.quantity * discountRate / 100;
  }

  private getItemTax(item: CartItem): number {
    const taxableAmount = (item.price * item.quantity) - this.getItemDiscount(item);
    const taxRate = Number(item.taxRate || 0);
    return taxableAmount * taxRate / 100;
  }

  private persistCart(cartItems: CartItem[]): void {
    if (this.isBrowser()) {
      localStorage.setItem(this.storageKey, JSON.stringify(cartItems));
    }

    this.cartItemsSubject.next([...cartItems]);
  }

  private readCartItems(): CartItem[] {
    if (!this.isBrowser()) {
      return [];
    }

    const rawCart = localStorage.getItem(this.storageKey);

    if (!rawCart) {
      return [];
    }

    try {
      const parsedCart = JSON.parse(rawCart);
      return Array.isArray(parsedCart) ? parsedCart : [];
    } catch (error) {
      console.error('Failed to parse cart items from localStorage', error);
      return [];
    }
  }

  private isBrowser(): boolean {
    return typeof window !== 'undefined' && typeof localStorage !== 'undefined';
  }
}
