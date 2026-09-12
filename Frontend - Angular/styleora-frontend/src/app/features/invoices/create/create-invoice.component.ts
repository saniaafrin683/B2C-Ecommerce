import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Invoice } from '../invoice.model';
import { InvoiceService } from '../invoice.service';
import { SettingsService } from '../../../core/services/settings.service';

@Component({
  selector: 'app-create-invoice',
  templateUrl: './create-invoice.component.html',
  styleUrls: ['./create-invoice.component.css']
})
export class CreateInvoiceComponent {
  submitting = false;
  errorMessage = '';

  readonly paymentStatuses = ['Pending', 'Paid', 'Completed', 'Failed', 'Cancelled', 'Inactive'];
  readonly paymentMethods = ['Cash', 'Bank Transfer', 'Visa', 'Mastercard', 'Paypal'];

  invoiceForm: Invoice = this.createInitialForm();

  constructor(
    private invoiceService: InvoiceService,
    private settingsService: SettingsService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.invoiceForm.invoiceNumber.trim() ||
        this.invoiceForm.orderId === null ||
        this.invoiceForm.orderId === undefined ||
        !this.invoiceForm.customerName.trim() ||
        this.invoiceForm.totalAmount === null ||
        this.invoiceForm.totalAmount === undefined ||
        !this.invoiceForm.paymentStatus.trim() ||
        !this.invoiceForm.issueDate ||
        !this.invoiceForm.dueDate) {
      this.errorMessage = 'Invoice Number, Order ID, Customer Name, Total Amount, Payment Status, Issue Date, and Due Date are required.';
      return;
    }

    this.submitting = true;

    const payload: Invoice = {
      ...this.invoiceForm,
      invoiceNumber: this.invoiceForm.invoiceNumber.trim(),
      orderId: Number(this.invoiceForm.orderId ?? 0),
      customerName: this.invoiceForm.customerName.trim(),
      customerEmail: (this.invoiceForm.customerEmail || '').trim(),
      billingAddress: (this.invoiceForm.billingAddress || '').trim(),
      subtotal: Number(this.invoiceForm.subtotal ?? 0),
      tax: Number(this.invoiceForm.tax ?? 0),
      discount: Number(this.invoiceForm.discount ?? 0),
      shippingCost: Number(this.invoiceForm.shippingCost ?? 0),
      totalAmount: Number(this.invoiceForm.totalAmount ?? 0),
      paymentStatus: this.invoiceForm.paymentStatus.trim(),
      paymentMethod: (this.invoiceForm.paymentMethod || '').trim(),
      issueDate: this.invoiceForm.issueDate,
      dueDate: this.invoiceForm.dueDate,
      notes: (this.invoiceForm.notes || '').trim()
    };

    this.invoiceService.createInvoice(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/invoices/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create invoice.';
      }
    });
  }

  onReset(): void {
    this.invoiceForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/invoices/list']);
  }

  private createInitialForm(): Invoice {
    const today = new Date().toISOString().split('T')[0];
    const invoicePrefix = this.settingsService.getInvoicePrefix();

    return {
      id: 0,
      invoiceNumber: `${invoicePrefix}-${Date.now().toString().slice(-8)}`,
      orderId: 0,
      customerName: '',
      customerEmail: '',
      billingAddress: '',
      subtotal: 0,
      tax: 0,
      discount: 0,
      shippingCost: 0,
      totalAmount: 0,
      paymentStatus: 'Pending',
      paymentMethod: 'Cash',
      issueDate: today,
      dueDate: today,
      notes: ''
    };
  }
}
