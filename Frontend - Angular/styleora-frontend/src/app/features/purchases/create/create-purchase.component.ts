import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Product } from '../../products/product.model';
import { ProductService } from '../../products/product.service';
import { Purchase, PurchaseLineItem } from '../purchase.model';
import { PurchaseService } from '../purchase.service';

@Component({
  selector: 'app-create-purchase',
  templateUrl: './create-purchase.component.html',
  styleUrls: ['./create-purchase.component.css']
})
export class CreatePurchaseComponent implements OnInit {
  products: Product[] = [];
  purchaseForm: Purchase = this.createInitialForm();
  loadingProducts = false;
  submitting = false;
  errorMessage = '';
  showOptionalNotes = false;

  readonly purchaseStatuses = ['Pending', 'Received', 'Completed', 'Cancelled'];

  readonly supplierOptions: string[] = [
    'Styleora Default Supplier',
    'Dhaka Fashion Supply',
    'Lerkon Wholesale',
    'Jamandi Saree House',
    'Fashion Wholesale BD'
  ];

  constructor(
    private purchaseService: PurchaseService,
    private productService: ProductService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.loadingProducts = true;
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.products = products || [];
        this.loadingProducts = false;
      },
      error: () => {
        this.loadingProducts = false;
        this.errorMessage = 'Failed to load products for purchase items.';
      }
    });
  }

  addItemRow(): void {
    this.purchaseForm.items = [
      ...this.purchaseForm.items,
      this.createEmptyItem()
    ];
  }

  removeItemRow(index: number): void {
    if (this.purchaseForm.items.length === 1) {
      this.purchaseForm.items = [this.createEmptyItem()];
    } else {
      this.purchaseForm.items = this.purchaseForm.items.filter((_, itemIndex) => itemIndex !== index);
    }

    this.recalculateTotals();
  }

  onProductChange(item: PurchaseLineItem): void {
    const product = this.products.find((entry) => entry.id === item.productId);

    if (!product) {
      item.productName = '';
      item.category = '';
      item.unitPrice = 0;
      item.availableStock = 0;
      item.subtotal = 0;
      this.recalculateTotals();
      return;
    }

    item.productName = product.name;
    item.category = product.category;
    item.unitPrice = Number(product.price || 0);
    item.availableStock = Number(product.stock || 0);
    item.quantity = Math.max(1, Number(item.quantity || 1));
    item.subtotal = item.quantity * item.unitPrice;
    this.recalculateTotals();
  }

  onItemValueChange(item: PurchaseLineItem): void {
    item.quantity = Math.max(1, Number(item.quantity || 1));
    item.unitPrice = Math.max(0, Number(item.unitPrice || 0));
    item.subtotal = item.quantity * item.unitPrice;
    this.recalculateTotals();
  }

  onTotalsChange(): void {
    this.recalculateTotals();
  }

  onSave(): void {
    this.errorMessage = '';
    this.recalculateTotals();

    if (!this.purchaseForm.supplierName.trim()) {
      this.errorMessage = 'Supplier is required.';
      return;
    }

    if (!this.purchaseForm.purchaseDate) {
      this.errorMessage = 'Purchase date is required.';
      return;
    }

    const validItems = this.purchaseForm.items.filter((item) => item.productId != null);

    if (validItems.length === 0) {
      this.errorMessage = 'Add at least one product row.';
      return;
    }

    const hasInvalidRow = validItems.some((item) => !item.productId || item.quantity <= 0);

    if (hasInvalidRow) {
      this.errorMessage = 'Each purchase item must have a product and quantity.';
      return;
    }

    this.submitting = true;

    const payload: Purchase = {
      ...this.purchaseForm,
      purchaseId: this.purchaseForm.purchaseId.trim(),
      supplierName: this.purchaseForm.supplierName.trim(),
      supplierEmail: (this.purchaseForm.supplierEmail || '').trim(),
      supplierPhone: (this.purchaseForm.supplierPhone || '').trim(),
      supplierAddress: (this.purchaseForm.supplierAddress || '').trim(),
      notes: (this.purchaseForm.notes || '').trim(),
      items: validItems.map((item) => ({
        ...item,
        quantity: Math.max(1, Number(item.quantity || 1)),
        unitPrice: Math.max(0, Number(item.unitPrice || 0)),
        subtotal: Math.max(0, Number(item.subtotal || 0))
      }))
    };

    this.purchaseService.createPurchase(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/purchases/list']);
      },
      error: (error) => {
        console.error('Failed to create purchase', error);
        this.submitting = false;
        this.errorMessage = typeof error?.error === 'string' && error.error.trim()
          ? error.error
          : 'Failed to create purchase.';
      }
    });
  }

  onReset(): void {
    this.purchaseForm = this.createInitialForm();
    this.errorMessage = '';
    this.showOptionalNotes = false;
  }

  onCancel(): void {
    this.router.navigate(['/purchases/list']);
  }

  trackByIndex(index: number): number {
    return index;
  }

  toggleOptionalNotes(): void {
    this.showOptionalNotes = !this.showOptionalNotes;
  }

  private recalculateTotals(): void {
    const subtotal = this.purchaseForm.items.reduce((sum, item) => {
      const lineSubtotal = Math.max(0, Number(item.quantity || 0)) * Math.max(0, Number(item.unitPrice || 0));
      item.subtotal = lineSubtotal;
      return sum + lineSubtotal;
    }, 0);

    const discount = Math.max(0, Number(this.purchaseForm.discount || 0));
    const tax = Math.max(0, Number(this.purchaseForm.tax || 0));
    const shippingCost = Math.max(0, Number(this.purchaseForm.shippingCost || 0));
    const paidAmount = Math.max(0, Number(this.purchaseForm.paidAmount || 0));

    this.purchaseForm.subtotal = subtotal;
    this.purchaseForm.totalAmount = Math.max(subtotal - discount + tax + shippingCost, 0);
    this.purchaseForm.dueAmount = Math.max(this.purchaseForm.totalAmount - paidAmount, 0);
  }

  private createInitialForm(): Purchase {
    return {
      id: 0,
      purchaseId: this.generatePurchaseId(),
      supplierName: '',
      supplierEmail: '',
      supplierPhone: '',
      supplierAddress: '',
      items: [this.createEmptyItem()],
      purchaseStatus: 'Pending',
      purchaseDate: new Date().toISOString().split('T')[0],
      totalAmount: 0,
      paymentMethod: 'Cash',
      paymentStatus: 'Pending',
      paidAmount: 0,
      dueAmount: 0,
      subtotal: 0,
      discount: 0,
      tax: 0,
      shippingCost: 0,
      notes: '',
      stockApplied: false
    };
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

  private generatePurchaseId(): string {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 900) + 100;
    return `PUR-${timestamp}${random}`;
  }
}