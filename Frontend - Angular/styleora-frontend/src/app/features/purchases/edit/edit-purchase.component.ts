import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Product } from '../../products/product.model';
import { ProductService } from '../../products/product.service';
import { Purchase, PurchaseLineItem } from '../purchase.model';
import { PurchaseService } from '../purchase.service';

@Component({
  selector: 'app-edit-purchase',
  templateUrl: './edit-purchase.component.html',
  styleUrls: ['./edit-purchase.component.css']
})
export class EditPurchaseComponent implements OnInit {
  purchase: Purchase | undefined;
  products: Product[] = [];
  initialSnapshot = '';
  loading = true;
  submitting = false;
  errorMessage = '';

  readonly purchaseStatuses = ['Pending', 'Received', 'Completed', 'Cancelled'];
  readonly paymentStatuses = ['Pending', 'Paid', 'Partial'];
  readonly paymentMethods = ['Cash', 'Bank Transfer', 'Credit Card', 'Mobile Banking'];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private purchaseService: PurchaseService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadProducts();

    this.route.paramMap.subscribe((params) => {
      const idParam = params.get('id');

      if (!idParam || isNaN(Number(idParam))) {
        this.loading = false;
        this.errorMessage = 'Invalid purchase id.';
        return;
      }

      this.loadPurchase(Number(idParam));
    });
  }

  get itemsLocked(): boolean {
    return !!this.purchase?.stockApplied;
  }

  loadProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.products = products || [];
      },
      error: () => {
        this.errorMessage = 'Failed to load products.';
      }
    });
  }

  loadPurchase(id: number): void {
    this.loading = true;
    this.errorMessage = '';

    this.purchaseService.getPurchaseById(id).subscribe({
      next: (purchase) => {
        this.purchase = {
          ...purchase,
          items: purchase.items.map((item) => ({ ...item }))
        };
        this.loading = false;
        this.initialSnapshot = JSON.stringify(this.purchase);
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Purchase not found.';
      }
    });
  }

  addItemRow(): void {
    if (!this.purchase || this.itemsLocked) {
      return;
    }

    this.purchase.items = [...this.purchase.items, this.createEmptyItem()];
  }

  removeItemRow(index: number): void {
    if (!this.purchase || this.itemsLocked) {
      return;
    }

    if (this.purchase.items.length === 1) {
      this.purchase.items = [this.createEmptyItem()];
    } else {
      this.purchase.items = this.purchase.items.filter((_, itemIndex) => itemIndex !== index);
    }

    this.recalculateTotals();
  }

  onProductChange(item: PurchaseLineItem): void {
    if (this.itemsLocked) {
      return;
    }

    const product = this.products.find((entry) => entry.id === item.productId);
    if (!product) {
      item.productName = '';
      item.category = '';
      item.availableStock = 0;
      item.unitPrice = 0;
      item.subtotal = 0;
      this.recalculateTotals();
      return;
    }

    item.productName = product.name;
    item.category = product.category;
    item.availableStock = Number(product.stock || 0);
    item.unitPrice = Number(product.price || 0);
    item.quantity = Math.max(1, Number(item.quantity || 1));
    item.subtotal = item.quantity * item.unitPrice;
    this.recalculateTotals();
  }

  onItemValueChange(item: PurchaseLineItem): void {
    if (this.itemsLocked) {
      return;
    }

    item.quantity = Math.max(1, Number(item.quantity || 1));
    item.unitPrice = Math.max(0, Number(item.unitPrice || 0));
    item.subtotal = item.quantity * item.unitPrice;
    this.recalculateTotals();
  }

  onTotalsChange(): void {
    this.recalculateTotals();
  }

  onSave(): void {
    if (!this.purchase) {
      return;
    }

    this.submitting = true;
    this.errorMessage = '';
    this.recalculateTotals();

    this.purchaseService.updatePurchase(this.purchase.id, this.purchase).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/purchases/list']);
      },
      error: (error) => {
        console.error('Failed to update purchase', error);
        this.submitting = false;
        this.errorMessage = typeof error?.error === 'string' && error.error.trim()
          ? error.error
          : 'Failed to update purchase.';
      }
    });
  }

  onReset(): void {
    if (!this.initialSnapshot) {
      return;
    }

    this.purchase = JSON.parse(this.initialSnapshot);
  }

  onCancel(): void {
    this.router.navigate(['/purchases/list']);
  }

  trackByIndex(index: number): number {
    return index;
  }

  private recalculateTotals(): void {
    if (!this.purchase) {
      return;
    }

    const subtotal = this.purchase.items.reduce((sum, item) => {
      const lineSubtotal = Math.max(0, Number(item.quantity || 0)) * Math.max(0, Number(item.unitPrice || 0));
      item.subtotal = lineSubtotal;
      return sum + lineSubtotal;
    }, 0);

    const discount = Math.max(0, Number(this.purchase.discount || 0));
    const tax = Math.max(0, Number(this.purchase.tax || 0));
    const shippingCost = Math.max(0, Number(this.purchase.shippingCost || 0));
    const paidAmount = Math.max(0, Number(this.purchase.paidAmount || 0));

    this.purchase.subtotal = subtotal;
    this.purchase.totalAmount = Math.max(subtotal - discount + tax + shippingCost, 0);
    this.purchase.dueAmount = Math.max(this.purchase.totalAmount - paidAmount, 0);
  }

  private createEmptyItem(): PurchaseLineItem {
    return {
      productId: null,
      productName: '',
      category: '',
      quantity: 1,
      unitPrice: 0,
      subtotal: 0,
      availableStock: 0
    };
  }
}
