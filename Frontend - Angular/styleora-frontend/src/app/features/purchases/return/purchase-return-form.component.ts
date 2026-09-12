import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { PurchaseReturn } from '../purchase-return.model';
import { PurchaseReturnService } from '../purchase-return.service';

@Component({
  selector: 'app-purchase-return-form',
  templateUrl: './purchase-return-form.component.html',
  styleUrls: ['./purchase-return-form.component.css']
})
export class PurchaseReturnFormComponent implements OnInit {
  returnForm: PurchaseReturn = this.createInitialForm();
  productName = '';
  quantity = 1;
  submitting = false;
  loading = false;
  errorMessage = '';
  isEditMode = false;
  private currentReturnId = 0;

  readonly returnStatuses = ['Pending', 'Completed', 'Rejected'];
  readonly refundStatuses = ['Pending', 'Refunded', 'Not Refunded'];

  constructor(
    private purchaseReturnService: PurchaseReturnService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    this.isEditMode = !!idParam;

    if (!idParam) {
      return;
    }

    this.currentReturnId = Number(idParam);
    this.loadPurchaseReturn(this.currentReturnId);
  }

  onSave(): void {
    this.errorMessage = '';

    if (!this.returnForm.purchaseOrderId.trim() ||
        !this.returnForm.supplierName.trim() ||
        !this.returnForm.returnDate ||
        !(this.returnForm.returnReason || '').trim() ||
        !this.productName.trim() ||
        !this.quantity ||
        !this.returnForm.returnStatus ||
        !this.returnForm.refundStatus ||
        this.returnForm.totalAmount === null ||
        this.returnForm.totalAmount === undefined ||
        this.returnForm.totalAmount === 0) {
      this.errorMessage = 'Purchase Order ID, Supplier, Return Date, Return Reason, Product Name, Quantity, Return Status, Refund Status, and Total Amount are required.';
      return;
    }

    this.submitting = true;

    const payload: PurchaseReturn = {
      ...this.returnForm,
      id: this.currentReturnId,
      returnId: this.returnForm.returnId,
      purchaseOrderId: this.returnForm.purchaseOrderId.trim(),
      supplierName: this.returnForm.supplierName.trim(),
      returnReason: (this.returnForm.returnReason || '').trim(),
      returnStatus: this.returnForm.returnStatus,
      refundStatus: this.returnForm.refundStatus,
      totalAmount: Number(this.returnForm.totalAmount ?? 0),
      subtotal: Number(this.returnForm.totalAmount ?? 0),
      tax: 0,
      discount: 0,
      items: [
        {
          product: this.productName.trim(),
          sku: '',
          quantity: Number(this.quantity || 0),
          unitCost: 0,
          discount: 0,
          tax: 0,
          total: Number(this.returnForm.totalAmount ?? 0)
        }
      ]
    };

    const request$ = this.isEditMode
      ? this.purchaseReturnService.updatePurchaseReturn(this.currentReturnId, payload)
      : this.purchaseReturnService.createPurchaseReturn(payload);

    request$.subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/purchases/return']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = this.isEditMode ? 'Failed to update purchase return.' : 'Failed to create purchase return.';
      }
    });
  }

  onReset(): void {
    if (this.isEditMode) {
      this.loadPurchaseReturn(this.currentReturnId);
      return;
    }

    this.returnForm = this.createInitialForm();
    this.productName = '';
    this.quantity = 1;
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/purchases/return']);
  }

  goBack(): void {
    this.router.navigate(['/purchases/return']);
  }

  private loadPurchaseReturn(id: number): void {
    this.loading = true;
    this.errorMessage = '';

    this.purchaseReturnService.getPurchaseReturnById(id).subscribe({
      next: (purchaseReturn) => {
        this.loading = false;
        this.currentReturnId = purchaseReturn.id;
        this.returnForm = {
          ...purchaseReturn,
          returnStatus: this.normalizeReturnStatus(purchaseReturn.returnStatus),
          refundStatus: this.normalizeRefundStatus(purchaseReturn.refundStatus)
        };
        this.productName = purchaseReturn.items[0]?.product || '';
        this.quantity = purchaseReturn.items[0]?.quantity || 1;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load purchase return.';
      }
    });
  }

  private createInitialForm(): PurchaseReturn {
    return {
      id: 0,
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

  private normalizeReturnStatus(status: string): string {
    return this.returnStatuses.includes(status) ? status : 'Pending';
  }

  private normalizeRefundStatus(status: string): string {
    return this.refundStatuses.includes(status) ? status : 'Pending';
  }
}
