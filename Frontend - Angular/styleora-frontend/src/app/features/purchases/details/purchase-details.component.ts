import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Purchase, PurchaseLineItem } from '../purchase.model';
import { PurchaseService } from '../purchase.service';

@Component({
  selector: 'app-purchase-details',
  templateUrl: './purchase-details.component.html',
  styleUrls: ['./purchase-details.component.css']
})
export class PurchaseDetailsComponent implements OnInit {
  purchase: Purchase | undefined;
  loading = true;
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private purchaseService: PurchaseService
  ) {}

  ngOnInit(): void {
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

  loadPurchase(id: number): void {
    this.loading = true;
    this.errorMessage = '';

    this.purchaseService.getPurchaseById(id).subscribe({
      next: (purchase) => {
        this.purchase = purchase;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Purchase details not found.';
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/purchases/list']);
  }

  onEdit(): void {
    if (!this.purchase) {
      return;
    }

    this.router.navigate(['/purchases/edit', this.purchase.id]);
  }

  getStatusClass(status: string | undefined): string {
    const normalized = (status || '').toLowerCase();

    if (normalized.includes('complete') || normalized.includes('receive')) {
      return 'pill-success';
    }

    if (normalized.includes('cancel')) {
      return 'pill-danger';
    }

    return 'pill-warning';
  }

  getItemCount(): number {
    return (this.purchase?.items || []).reduce((sum, item) => sum + Number(item.quantity || 0), 0);
  }

  getLineTotal(item: PurchaseLineItem): number {
    return Number(item.subtotal || 0);
  }
}
