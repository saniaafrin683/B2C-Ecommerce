import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { ReturnRequest } from '../return-request.model';
import { ReturnRequestService } from '../return-request.service';

@Component({
  selector: 'app-create-return-request',
  templateUrl: './create-return-request.component.html',
  styleUrls: ['./create-return-request.component.css']
})
export class CreateReturnRequestComponent {
  submitting = false;
  errorMessage = '';

  returnRequestForm: ReturnRequest = this.createInitialForm();

  constructor(
    private returnRequestService: ReturnRequestService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.returnRequestForm.orderId || !this.returnRequestForm.customerId || !this.returnRequestForm.reason.trim()) {
      this.errorMessage = 'Order ID, Customer ID, and Reason are required.';
      return;
    }

    this.submitting = true;

    const payload: ReturnRequest = {
      ...this.returnRequestForm,
      orderId: Number(this.returnRequestForm.orderId ?? 0),
      customerId: Number(this.returnRequestForm.customerId ?? 0),
      productId: this.returnRequestForm.productId ?? null,
      note: (this.returnRequestForm.note || '').trim(),
      reason: this.returnRequestForm.reason.trim(),
      status: 'Pending',
      requestedAt: '',
      updatedAt: ''
    };

    this.returnRequestService.createReturnRequest(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/returns/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create return request.';
      }
    });
  }

  onReset(): void {
    this.returnRequestForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/returns/list']);
  }

  private createInitialForm(): ReturnRequest {
    return {
      id: 0,
      orderId: 0,
      customerId: 0,
      productId: null,
      orderReference: '',
      customerName: '',
      reason: '',
      note: '',
      status: 'Pending',
      requestedAt: '',
      updatedAt: ''
    };
  }
}
