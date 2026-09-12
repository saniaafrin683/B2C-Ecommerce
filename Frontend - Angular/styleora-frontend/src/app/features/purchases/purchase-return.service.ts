import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, catchError, map, of } from 'rxjs';
import { PurchaseReturn, PurchaseReturnLineItem } from './purchase-return.model';

interface PurchaseReturnApiModel {
  id?: number;
  returnId?: string;
  purchaseOrderId?: string;
  supplierName?: string;
  supplierEmail?: string;
  supplierPhone?: string;
  returnDate?: string;
  returnReason?: string;
  returnStatus?: string;
  refundStatus?: string;
  paymentMethod?: string;
  items?: string | PurchaseReturnLineItem[];
  subtotal?: number;
  tax?: number;
  discount?: number;
  totalAmount?: number;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class PurchaseReturnService {
  private readonly baseUrl = 'http://localhost:8080/purchase-returns';
  private readonly localStorageKey = 'styleora-admin-purchase-returns';

  constructor(private http: HttpClient) {}

  getPurchaseReturns(): Observable<PurchaseReturn[]> {
    return this.http
      .get<PurchaseReturnApiModel[]>(`${this.baseUrl}/list`)
      .pipe(
        map((returns) => this.mergeWithLocalReturns((returns || []).map((purchaseReturn) => this.toFrontendReturn(purchaseReturn)))),
        catchError(() => of(this.getLocalReturns()))
      );
  }

  getPurchaseReturnById(id: number): Observable<PurchaseReturn> {
    const localReturn = this.getLocalReturns().find((purchaseReturn) => purchaseReturn.id === id);
    if (localReturn && localReturn.id < 0) {
      return of(localReturn);
    }

    return this.http
      .get<PurchaseReturnApiModel>(`${this.baseUrl}/${id}`)
      .pipe(
        map((purchaseReturn) => localReturn || this.toFrontendReturn(purchaseReturn)),
        catchError(() => of(localReturn || this.createEmptyReturn(id)))
      );
  }

  createPurchaseReturn(purchaseReturn: PurchaseReturn): Observable<PurchaseReturn> {
    return this.http
      .post<PurchaseReturnApiModel>(`${this.baseUrl}/create`, this.toBackendReturn(purchaseReturn))
      .pipe(
        map((createdReturn) => {
          const savedReturn = this.toFrontendReturn(createdReturn);
          this.removeLocalReturn(savedReturn.id);
          return savedReturn;
        }),
        catchError(() => {
          const localReturn: PurchaseReturn = {
            ...purchaseReturn,
            id: this.generateLocalId(),
            returnId: purchaseReturn.returnId || this.generateReturnId()
          };
          this.upsertLocalReturn(localReturn);
          return of(localReturn);
        })
      );
  }

  updatePurchaseReturn(id: number, purchaseReturn: PurchaseReturn): Observable<PurchaseReturn> {
    if (id < 0) {
      const localReturn = {
        ...purchaseReturn,
        id
      };
      this.upsertLocalReturn(localReturn);
      return of(localReturn);
    }

    return this.http
      .put<PurchaseReturnApiModel>(`${this.baseUrl}/update/${id}`, this.toBackendReturn(purchaseReturn))
      .pipe(
        map((updatedReturn) => {
          const savedReturn = this.toFrontendReturn(updatedReturn);
          this.removeLocalReturn(id);
          return savedReturn;
        }),
        catchError(() => {
          const localReturn = {
            ...purchaseReturn,
            id
          };
          this.upsertLocalReturn(localReturn);
          return of(localReturn);
        })
      );
  }

  deletePurchaseReturn(id: number): Observable<void> {
    if (id < 0) {
      this.removeLocalReturn(id);
      return of(void 0);
    }

    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  private toFrontendReturn(purchaseReturn: PurchaseReturnApiModel): PurchaseReturn {
    return {
      id: Number(purchaseReturn.id ?? 0),
      returnId: purchaseReturn.returnId || '',
      purchaseOrderId: purchaseReturn.purchaseOrderId || '',
      supplierName: purchaseReturn.supplierName || '',
      supplierEmail: purchaseReturn.supplierEmail || '',
      supplierPhone: purchaseReturn.supplierPhone || '',
      returnDate: purchaseReturn.returnDate || '',
      returnReason: purchaseReturn.returnReason || '',
      returnStatus: purchaseReturn.returnStatus || 'Pending',
      refundStatus: purchaseReturn.refundStatus || 'Pending',
      paymentMethod: purchaseReturn.paymentMethod || '',
      items: this.parseItems(purchaseReturn.items),
      subtotal: Number(purchaseReturn.subtotal ?? 0),
      tax: Number(purchaseReturn.tax ?? 0),
      discount: Number(purchaseReturn.discount ?? 0),
      totalAmount: Number(purchaseReturn.totalAmount ?? 0),
      notes: purchaseReturn.notes || ''
    };
  }

  private toBackendReturn(purchaseReturn: PurchaseReturn): PurchaseReturnApiModel {
    return {
      id: purchaseReturn.id,
      returnId: purchaseReturn.returnId,
      purchaseOrderId: purchaseReturn.purchaseOrderId,
      supplierName: purchaseReturn.supplierName,
      supplierEmail: purchaseReturn.supplierEmail || '',
      supplierPhone: purchaseReturn.supplierPhone || '',
      returnDate: purchaseReturn.returnDate,
      returnReason: purchaseReturn.returnReason || '',
      returnStatus: purchaseReturn.returnStatus,
      refundStatus: purchaseReturn.refundStatus,
      paymentMethod: purchaseReturn.paymentMethod || '',
      items: JSON.stringify(purchaseReturn.items || []),
      subtotal: Number(purchaseReturn.subtotal ?? 0),
      tax: Number(purchaseReturn.tax ?? 0),
      discount: Number(purchaseReturn.discount ?? 0),
      totalAmount: Number(purchaseReturn.totalAmount ?? 0),
      notes: purchaseReturn.notes || ''
    };
  }

  private parseItems(items: string | PurchaseReturnLineItem[] | undefined): PurchaseReturnLineItem[] {
    if (!items) {
      return [];
    }

    if (Array.isArray(items)) {
      return items.map((item) => ({ ...item }));
    }

    try {
      const parsedItems = JSON.parse(items);
      return Array.isArray(parsedItems)
        ? parsedItems.map((item) => ({
            product: item?.product || '',
            sku: item?.sku || '',
            quantity: Number(item?.quantity ?? 0),
            unitCost: Number(item?.unitCost ?? 0),
            discount: Number(item?.discount ?? 0),
            tax: Number(item?.tax ?? 0),
            total: Number(item?.total ?? 0)
          }))
        : [];
    } catch {
      return [];
    }
  }

  private getLocalReturns(): PurchaseReturn[] {
    try {
      const storedValue = localStorage.getItem(this.localStorageKey);
      if (!storedValue) {
        return [];
      }

      const parsedValue = JSON.parse(storedValue);
      return Array.isArray(parsedValue)
        ? parsedValue.map((purchaseReturn) => this.toFrontendReturn(purchaseReturn))
        : [];
    } catch {
      return [];
    }
  }

  private upsertLocalReturn(purchaseReturn: PurchaseReturn): void {
    const localReturns = this.getLocalReturns();
    const index = localReturns.findIndex((item) => item.id === purchaseReturn.id);

    if (index >= 0) {
      localReturns[index] = { ...purchaseReturn };
    } else {
      localReturns.unshift({ ...purchaseReturn });
    }

    localStorage.setItem(this.localStorageKey, JSON.stringify(localReturns));
  }

  private removeLocalReturn(id: number): void {
    const localReturns = this.getLocalReturns().filter((purchaseReturn) => purchaseReturn.id !== id);
    localStorage.setItem(this.localStorageKey, JSON.stringify(localReturns));
  }

  private mergeWithLocalReturns(apiReturns: PurchaseReturn[]): PurchaseReturn[] {
    const localReturns = this.getLocalReturns();
    const mergedReturns = new Map<number, PurchaseReturn>();

    apiReturns.forEach((purchaseReturn) => {
      mergedReturns.set(purchaseReturn.id, purchaseReturn);
    });

    localReturns.forEach((purchaseReturn) => {
      mergedReturns.set(purchaseReturn.id, purchaseReturn);
    });

    return Array.from(mergedReturns.values()).sort((left, right) => right.id - left.id);
  }

  private generateLocalId(): number {
    const ids = this.getLocalReturns()
      .map((purchaseReturn) => purchaseReturn.id)
      .filter((id) => id < 0);

    return ids.length ? Math.min(...ids) - 1 : -1;
  }

  private generateReturnId(): string {
    return `PR-${Date.now().toString().slice(-6)}`;
  }

  private createEmptyReturn(id: number): PurchaseReturn {
    return {
      id,
      returnId: '',
      purchaseOrderId: '',
      supplierName: '',
      supplierEmail: '',
      supplierPhone: '',
      returnDate: '',
      returnReason: '',
      returnStatus: 'Pending',
      refundStatus: 'Pending',
      paymentMethod: '',
      items: [],
      subtotal: 0,
      tax: 0,
      discount: 0,
      totalAmount: 0,
      notes: ''
    };
  }
}
