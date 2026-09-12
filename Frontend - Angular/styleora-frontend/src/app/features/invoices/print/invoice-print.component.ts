import { Component, OnDestroy, OnInit, ViewEncapsulation } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { SettingsService } from '../../../core/services/settings.service';
import { Invoice } from '../invoice.model';
import { InvoiceService } from '../invoice.service';
import { Order, OrderItem } from '../../orders/order.model';
import { OrdersService } from '../../orders/orders.service';

@Component({
  selector: 'app-invoice-print',
  templateUrl: './invoice-print.component.html',
  styleUrls: ['./invoice-print.component.css'],
  encapsulation: ViewEncapsulation.None
})
export class InvoicePrintComponent implements OnInit, OnDestroy {
  invoiceId!: number;
  invoice: Invoice | null = null;
  order: Order | null = null;
  loading = false;
  errorMessage = '';
  readonly settings = this.settingsService.getCurrentSettings();
  readonly fallbackProductImage = 'assets/images/category/default-product.png';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private invoiceService: InvoiceService,
    private ordersService: OrdersService,
    private settingsService: SettingsService
  ) {}

  ngOnInit(): void {
    document.body.classList.add('invoice-print-mode');

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

  ngOnDestroy(): void {
    document.body.classList.remove('invoice-print-mode');
  }

  loadInvoice(): void {
    this.loading = true;
    this.errorMessage = '';
    this.invoiceService.getInvoiceById(this.invoiceId).subscribe({
      next: (invoice) => {
        this.invoice = invoice;
        this.loadOrderDetails(invoice.orderId);
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load invoice for printing.';
      }
    });
  }

  loadOrderDetails(orderId: number): void {
    forkJoin({
      order: this.ordersService.getOrderById(orderId).pipe(
        catchError(() => of(null))
      )
    }).subscribe({
      next: ({ order }) => {
        this.order = order;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load invoice for printing.';
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/invoices/details', this.invoiceId]);
  }

  onPrint(): void {
    window.print();
  }

  getLineItems(): OrderItem[] {
    const orderItems = this.order?.orderItems || [];

    if (orderItems.length > 0) {
      return orderItems;
    }

    return [{
      productName: 'Order Summary',
      productImage: this.fallbackProductImage,
      size: '',
      color: '',
      unitPrice: Number(this.invoice?.subtotal || 0),
      quantity: Number(this.order?.items || 1),
      lineTotal: Number(this.invoice?.totalAmount || 0)
    }];
  }

  getCustomerPhone(): string {
    return this.order?.customerPhone || this.order?.deliveryNumber || 'Not set';
  }

  getCustomerAddress(): string {
    return this.order?.shippingAddress || this.invoice?.billingAddress || 'Not set';
  }

  getCustomerLocation(): string {
    return 'City/Country not available';
  }

  getDocumentDate(): string {
    return this.order?.createdAt || this.invoice?.issueDate || '';
  }

  getDocumentTime(): string {
    return '10:00 AM';
  }

  getSalesPerson(): string {
    return 'Admin';
  }

  getStoreTagline(): string {
    return this.settings.storeTagline || 'Fashion Commerce';
  }

  getOrderReference(): string {
    return this.invoice?.orderReference || (this.invoice?.orderId != null ? `ORD-${this.invoice.orderId}` : 'Not set');
  }

  getItemRegularUnitPrice(item: OrderItem): number {
    return Number((item.originalUnitPrice ?? item.unitPrice ?? 0).toFixed(2));
  }

  getItemDiscountedUnitPrice(item: OrderItem): number {
    return Number((item.discountedUnitPrice ?? item.unitPrice ?? 0).toFixed(2));
  }

  getItemDiscountTotal(item: OrderItem): number {
    if (typeof item.productDiscountLineTotal === 'number') {
      return Number(item.productDiscountLineTotal.toFixed(2));
    }

    const originalLine = typeof item.originalLineTotal === 'number'
      ? item.originalLineTotal
      : this.getItemRegularUnitPrice(item) * Number(item.quantity || 0);
    return Number((originalLine - Number(item.lineTotal || 0)).toFixed(2));
  }
}
