import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { finalize, switchMap } from 'rxjs/operators';
import { Order } from '../order.model';
import { OrdersService } from '../orders.service';
import { InvoiceService } from '../../invoices/invoice.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-create-order',
  templateUrl: './create-order.component.html',
  styleUrls: ['./create-order.component.css']
})
export class CreateOrderComponent {

  orderForm: Order = this.createInitialForm();
  submitting = false;
  loading = false;
  errorMessage = '';

  priorityOptions: string[] = ['High', 'Medium', 'Low'];
  paymentStatusOptions: string[] = ['Pending', 'Paid', 'Unpaid', 'Refunded'];
  orderStatusOptions: string[] = ['Pending', 'Confirmed', 'In Progress', 'Shipped', 'Delivered', 'Cancelled'];

  constructor(
    private ordersService: OrdersService,
    private invoiceService: InvoiceService,
    private router: Router,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  createInitialForm(): Order {
    return {
      orderId: '',
      createdAt: this.getTodayDate(),
      customerName: '',
      priority: '',
      totalAmount: 0,
      paymentStatus: 'Pending',
      items: 1,
      deliveryNumber: '',
      orderStatus: 'Pending'
    };
  }

  getTodayDate(): string {
    return new Date().toISOString().split('T')[0];
  }

  onSave(): void {
    this.submitting = true;
    this.errorMessage = '';
    this.loadingService.show();

    const payload: Order = {
      orderId: (this.orderForm.orderId || '').trim(),
      createdAt: this.orderForm.createdAt || this.getTodayDate(),
      customerName: (this.orderForm.customerName || '').trim(),
      priority: this.orderForm.priority || '',
      totalAmount: Number(this.orderForm.totalAmount ?? 0),
      paymentStatus: this.orderForm.paymentStatus || 'Pending',
      items: Number(this.orderForm.items ?? 0),
      deliveryNumber: (this.orderForm.deliveryNumber || '').trim(),
      orderStatus: this.orderForm.orderStatus || 'Pending'
    };

    this.ordersService.createOrder(payload).pipe(
      switchMap((createdOrder) => {
        if (!createdOrder?.id) {
          throw new Error('Created order not found for invoice generation.');
        }

        return this.invoiceService.createInvoice(
          this.invoiceService.buildInvoiceFromOrder(createdOrder, Number(createdOrder.id))
        );
      }),
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Order created successfully.');
        this.router.navigate(['/orders/list']);
      },
      error: () => {
        this.errorMessage = 'Failed to create order or generate invoice.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onReset(): void {
    this.orderForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/orders/list']);
  }
}
