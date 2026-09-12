import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Purchase, PurchaseLineItem } from './purchase.model';

interface PurchaseItemApiModel {
  id?: number;
  productId?: number | null;
  productName?: string;
  category?: string;
  quantity?: number;
  unitPrice?: number;
  subtotal?: number;
}

interface PurchaseApiModel {
  id?: number;
  purchaseId?: string;
  supplierName?: string;
  supplierEmail?: string;
  supplierPhone?: string;
  supplierAddress?: string;
  purchaseStatus?: string;
  purchaseDate?: string;
  totalAmount?: number;
  subtotal?: number;
  discount?: number;
  tax?: number;
  shippingCost?: number;
  paymentMethod?: string;
  paymentStatus?: string;
  paidAmount?: number;
  dueAmount?: number;
  notes?: string;
  stockApplied?: boolean;
  items?: PurchaseItemApiModel[];
}

interface PurchaseItemRequestModel {
  productId: number;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

interface PurchaseRequestModel {
  purchaseId: string;
  supplierName: string;
  supplierEmail: string;
  supplierPhone: string;
  supplierAddress: string;
  purchaseStatus: string;
  purchaseDate: string;
  totalAmount: number;
  subtotal: number;
  discount: number;
  tax: number;
  shippingCost: number;
  paymentMethod: string;
  paymentStatus: string;
  paidAmount: number;
  dueAmount: number;
  notes: string;
  items: PurchaseItemRequestModel[];
}

@Injectable({
  providedIn: 'root'
})
export class PurchaseService {
  private readonly baseUrl = `${environment.apiBaseUrl}/purchases`;

  constructor(private http: HttpClient) {}

  getPurchases(): Observable<Purchase[]> {
    return this.http.get<PurchaseApiModel[]>(`${this.baseUrl}/list`).pipe(
      map((purchases) => (purchases || []).map((purchase) => this.toFrontendPurchase(purchase)))
    );
  }

  getPurchaseById(id: number): Observable<Purchase> {
    return this.http.get<PurchaseApiModel>(`${this.baseUrl}/details/${id}`).pipe(
      map((purchase) => this.toFrontendPurchase(purchase))
    );
  }

  createPurchase(purchase: Purchase): Observable<Purchase> {
    return this.http.post<PurchaseApiModel>(`${this.baseUrl}/create`, this.toBackendPurchase(purchase)).pipe(
      map((createdPurchase) => this.toFrontendPurchase(createdPurchase))
    );
  }

  updatePurchase(id: number, purchase: Purchase): Observable<Purchase> {
    return this.http.put<PurchaseApiModel>(`${this.baseUrl}/update/${id}`, this.toBackendPurchase(purchase)).pipe(
      map((updatedPurchase) => this.toFrontendPurchase(updatedPurchase))
    );
  }

  deletePurchase(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  private toFrontendPurchase(purchase: PurchaseApiModel): Purchase {
    return {
      id: Number(purchase.id ?? 0),
      purchaseId: (purchase.purchaseId || '').trim(),
      supplierName: (purchase.supplierName || '').trim(),
      supplierEmail: (purchase.supplierEmail || '').trim(),
      supplierPhone: (purchase.supplierPhone || '').trim(),
      supplierAddress: (purchase.supplierAddress || '').trim(),
      purchaseStatus: (purchase.purchaseStatus || 'Pending').trim(),
      purchaseDate: purchase.purchaseDate || '',
      totalAmount: this.normalizeNumber(purchase.totalAmount),
      subtotal: this.normalizeNumber(purchase.subtotal),
      discount: this.normalizeNumber(purchase.discount),
      tax: this.normalizeNumber(purchase.tax),
      shippingCost: this.normalizeNumber(purchase.shippingCost),
      paymentMethod: (purchase.paymentMethod || '').trim(),
      paymentStatus: (purchase.paymentStatus || 'Pending').trim(),
      paidAmount: this.normalizeNumber(purchase.paidAmount),
      dueAmount: this.normalizeNumber(purchase.dueAmount),
      notes: (purchase.notes || '').trim(),
      stockApplied: !!purchase.stockApplied,
      items: (purchase.items || []).map((item) => this.toFrontendItem(item))
    };
  }

  private toFrontendItem(item: PurchaseItemApiModel): PurchaseLineItem {
    return {
      id: Number(item.id ?? 0) || undefined,
      productId: this.normalizeNullableId(item.productId),
      productName: (item.productName || '').trim(),
      category: (item.category || '').trim(),
      quantity: Math.max(1, this.normalizeNumber(item.quantity, 1)),
      unitPrice: this.normalizeNumber(item.unitPrice),
      subtotal: this.normalizeNumber(item.subtotal)
    };
  }

  private toBackendPurchase(purchase: Purchase): PurchaseRequestModel {
    return {
      purchaseId: purchase.purchaseId.trim(),
      supplierName: purchase.supplierName.trim(),
      supplierEmail: (purchase.supplierEmail || '').trim(),
      supplierPhone: (purchase.supplierPhone || '').trim(),
      supplierAddress: (purchase.supplierAddress || '').trim(),
      purchaseStatus: purchase.purchaseStatus,
      purchaseDate: purchase.purchaseDate,
      totalAmount: this.normalizeNumber(purchase.totalAmount),
      subtotal: this.normalizeNumber(purchase.subtotal),
      discount: this.normalizeNumber(purchase.discount),
      tax: this.normalizeNumber(purchase.tax),
      shippingCost: this.normalizeNumber(purchase.shippingCost),
      paymentMethod: (purchase.paymentMethod || '').trim(),
      paymentStatus: (purchase.paymentStatus || '').trim(),
      paidAmount: this.normalizeNumber(purchase.paidAmount),
      dueAmount: this.normalizeNumber(purchase.dueAmount),
      notes: (purchase.notes || '').trim(),
      items: (purchase.items || [])
        .filter((item) => item.productId != null)
        .map((item) => ({
          productId: Number(item.productId),
          quantity: Math.max(1, this.normalizeNumber(item.quantity, 1)),
          unitPrice: this.normalizeNumber(item.unitPrice),
          subtotal: this.normalizeNumber(item.subtotal)
        }))
    };
  }

  private normalizeNumber(value: number | string | null | undefined, fallback = 0): number {
    const normalized = Number(value ?? fallback);
    return Number.isFinite(normalized) ? normalized : fallback;
  }

  private normalizeNullableId(value: number | string | null | undefined): number | null {
    const normalized = Number(value);
    return Number.isFinite(normalized) && normalized > 0 ? normalized : null;
  }
}
