import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PurchaseReturn } from '../purchase-return.model';
import { PurchaseReturnService } from '../purchase-return.service';

@Component({
  selector: 'app-purchase-return',
  templateUrl: './purchase-return.component.html',
  styleUrls: ['./purchase-return.component.css']
})
export class PurchaseReturnComponent implements OnInit {
  purchaseReturns: PurchaseReturn[] = [];
  selectedReturn: PurchaseReturn | null = null;
  loading = false;
  errorMessage = '';

  constructor(
    private purchaseReturnService: PurchaseReturnService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadPurchaseReturns();
  }

  get totalReturns(): number {
    return this.purchaseReturns.length;
  }

  get pendingReturns(): number {
    return this.purchaseReturns.filter((item) => this.matches(item.returnStatus, 'pending')).length;
  }

  get completedReturns(): number {
    return this.purchaseReturns.filter((item) => this.matches(item.returnStatus, 'completed')).length;
  }

  get refundedReturns(): number {
    return this.purchaseReturns.filter((item) => this.matches(item.refundStatus, 'refund')).length;
  }

  loadPurchaseReturns(): void {
    this.loading = true;
    this.errorMessage = '';

    this.purchaseReturnService.getPurchaseReturns().subscribe({
      next: (returns) => {
        this.purchaseReturns = returns;
        this.loading = false;

        if (this.selectedReturn) {
          this.selectedReturn = this.purchaseReturns.find((item) => item.id === this.selectedReturn?.id) || null;
        }
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load purchase returns.';
      }
    });
  }

  openCreateForm(): void {
    this.router.navigate(['/purchases/return/create']);
  }

  onView(purchaseReturn: PurchaseReturn): void {
    this.selectedReturn = purchaseReturn;
  }

  onEdit(purchaseReturn: PurchaseReturn): void {
    this.router.navigate(['/purchases/return/edit', purchaseReturn.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this purchase return?');
    if (!confirmed) {
      return;
    }

    this.purchaseReturnService.deletePurchaseReturn(id).subscribe({
      next: () => {
        if (this.selectedReturn?.id === id) {
          this.selectedReturn = null;
        }
        this.loadPurchaseReturns();
      },
      error: () => {
        this.errorMessage = 'Failed to delete purchase return.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();

    if (normalized.includes('reject') || normalized.includes('cancel')) {
      return 'pill-danger';
    }

    if (normalized.includes('not refunded')) {
      return 'pill-danger';
    }

    if (normalized.includes('approved') || normalized.includes('complete') || normalized === 'refunded') {
      return 'pill-success';
    }

    return 'pill-warning';
  }

  getItemSummary(purchaseReturn: PurchaseReturn): string {
    return purchaseReturn.items.map((item) => `${item.product} x${item.quantity}`).join(', ');
  }

  getItemCount(purchaseReturn: PurchaseReturn): number {
    return purchaseReturn.items.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
  }

  private matches(value: string, expected: string): boolean {
    return (value || '').toLowerCase().includes(expected.toLowerCase());
  }
}
