import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Invoice } from '../../invoices/invoice.model';
import { InvoiceService } from '../../invoices/invoice.service';
import { Order } from '../../orders/order.model';
import { OrdersService } from '../../orders/orders.service';
import { Payment } from '../payment.model';
import { PaymentService } from '../payment.service';

@Component({
  selector: 'app-create-payment',
  templateUrl: './create-payment.component.html',
  styleUrls: ['./create-payment.component.css']
})
export class CreatePaymentComponent implements OnInit {
  loadingReferences = false;
  submitting = false;
  errorMessage = '';

  invoices: Invoice[] = [];
  orders: Order[] = [];

  readonly paymentStatuses = ['Pending', 'Paid', 'Completed', 'Failed', 'Cancelled', 'Processing'];
  readonly paymentMethods = ['Cash On Delivery', 'bKash', 'Nagad', 'Rocket', 'Bank Transfer', 'Visa', 'Mastercard', 'PayPal'];

  paymentForm: Payment = this.createInitialForm();

  constructor(
    private paymentService: PaymentService,
    private invoiceService: InvoiceService,
    private ordersService: OrdersService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadReferenceData();
  }

  loadReferenceData(): void {
    this.loadingReferences = true;
    this.errorMessage = '';

    this.invoiceService.getInvoices().subscribe({
      next: (invoices) => {
        this.invoices = invoices || [];
        this.ordersService.getAllOrders().subscribe({
          next: (orders) => {
            this.orders = (orders || []) as Order[];
            this.loadingReferences = false;
          },
          error: () => {
            this.loadingReferences = false;
            this.errorMessage = 'Failed to load order list.';
          }
        });
      },
      error: () => {
        this.loadingReferences = false;
        this.errorMessage = 'Failed to load invoice list.';
      }
    });
  }

  onInvoiceChange(): void {
    const invoice = this.invoices.find((item) => item.id === Number(this.paymentForm.invoiceId));
    if (!invoice) {
      return;
    }

    this.paymentForm.orderId = Number(invoice.orderId ?? 0);
    this.paymentForm.customerName = invoice.customerName || '';
    this.paymentForm.amount = Number(invoice.totalAmount ?? 0);
    this.paymentForm.paymentMethod = invoice.paymentMethod || this.paymentForm.paymentMethod;
    this.paymentForm.paymentStatus = invoice.paymentStatus || this.paymentForm.paymentStatus;
  }

  onOrderChange(): void {
    const order = this.orders.find((item) => Number(item.id) === Number(this.paymentForm.orderId));
    if (!order) {
      return;
    }

    this.paymentForm.customerName = order.customerName || this.paymentForm.customerName;
    this.paymentForm.amount = Number(order.totalAmount ?? this.paymentForm.amount ?? 0);
    this.paymentForm.paymentMethod = order.paymentMethod || this.paymentForm.paymentMethod;
    this.paymentForm.paymentStatus = order.paymentStatus || this.paymentForm.paymentStatus;
  }

  onSave(): void {
    this.errorMessage = '';

    if (!this.paymentForm.transactionId.trim() ||
        !this.paymentForm.invoiceId ||
        !this.paymentForm.orderId ||
        !this.paymentForm.customerName.trim() ||
        this.paymentForm.amount === null ||
        this.paymentForm.amount === undefined ||
        !this.paymentForm.paymentStatus.trim() ||
        !this.paymentForm.paymentDate) {
      this.errorMessage = 'Transaction ID, Invoice, Order, Customer Name, Amount, Payment Status, and Payment Date are required.';
      return;
    }

    this.submitting = true;

    const payload: Payment = {
      ...this.paymentForm,
      invoiceId: Number(this.paymentForm.invoiceId ?? 0),
      orderId: Number(this.paymentForm.orderId ?? 0),
      customerName: this.paymentForm.customerName.trim(),
      amount: Number(this.paymentForm.amount ?? 0),
      paymentMethod: (this.paymentForm.paymentMethod || '').trim(),
      transactionId: this.paymentForm.transactionId.trim(),
      paymentStatus: this.paymentForm.paymentStatus.trim(),
      paymentDate: this.paymentForm.paymentDate,
      notes: (this.paymentForm.notes || '').trim(),
      createdAt: this.paymentForm.createdAt,
      updatedAt: this.paymentForm.updatedAt
    };

    this.paymentService.createPayment(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/payments/list']);
      },
      error: (error: Error) => {
        this.submitting = false;
        this.errorMessage = error.message || 'Failed to create payment.';
      }
    });
  }

  onReset(): void {
    this.paymentForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/payments/list']);
  }

  private createInitialForm(): Payment {
    const today = new Date().toISOString().split('T')[0];

    return {
      id: 0,
      invoiceId: 0,
      orderId: 0,
      customerName: '',
      amount: 0,
      paymentMethod: 'Cash',
      transactionId: '',
      paymentStatus: 'Pending',
      paymentDate: today,
      notes: '',
      createdAt: today,
      updatedAt: today
    };
  }
}
