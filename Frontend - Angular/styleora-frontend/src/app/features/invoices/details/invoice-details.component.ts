import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Invoice } from '../invoice.model';
import { InvoiceService } from '../invoice.service';

@Component({
  selector: 'app-invoice-details',
  templateUrl: './invoice-details.component.html',
  styleUrls: ['./invoice-details.component.css']
})
export class InvoiceDetailsComponent implements OnInit {
  invoiceId!: number;
  invoice: Invoice | null = null;
  loading = false;
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private invoiceService: InvoiceService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.invoiceId = +id;
        this.loadInvoice();
      } else {
        this.router.navigate(['/invoices/list']);
      }
    });
  }

  loadInvoice(): void {
    this.loading = true;
    this.errorMessage = '';
    this.invoiceService.getInvoiceById(this.invoiceId).subscribe({
      next: (invoice) => {
        this.invoice = invoice;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load invoice details.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('paid')) {
      return 'pill-success';
    }
    if (normalized.includes('unpaid') || normalized.includes('failed')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  onBack(): void {
    this.router.navigate(['/invoices/list']);
  }

  onPrint(): void {
    this.router.navigate(['/invoices/print', this.invoiceId]);
  }
}
