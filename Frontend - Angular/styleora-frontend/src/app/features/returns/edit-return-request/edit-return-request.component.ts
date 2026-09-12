import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ReturnRequest } from '../return-request.model';
import { ReturnRequestService } from '../return-request.service';

@Component({
  selector: 'app-edit-return-request',
  templateUrl: './edit-return-request.component.html',
  styleUrls: ['./edit-return-request.component.css']
})
export class EditReturnRequestComponent implements OnInit {
  returnRequestId!: number;
  loading = false;
  submitting = false;
  errorMessage = '';

  readonly statuses = ['Pending', 'Approved', 'Rejected', 'Refunded'];
  returnRequestForm: ReturnRequest = this.createInitialForm();
  private initialSnapshot: ReturnRequest = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private returnRequestService: ReturnRequestService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.returnRequestId = +id;
        this.loadReturnRequest();
      } else {
        this.router.navigate(['/returns/list']);
      }
    });
  }

  loadReturnRequest(): void {
    this.loading = true;
    this.errorMessage = '';

    this.returnRequestService.getReturnRequestById(this.returnRequestId).subscribe({
      next: (returnRequest) => {
        this.returnRequestForm = { ...returnRequest };
        this.initialSnapshot = { ...returnRequest };
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load return request.';
      }
    });
  }

  onSave(): void {
    this.errorMessage = '';

    if (!this.returnRequestForm.status.trim()) {
      this.errorMessage = 'Status is required.';
      return;
    }

    this.submitting = true;

    const payload: ReturnRequest = {
      ...this.returnRequestForm,
      orderId: Number(this.returnRequestForm.orderId ?? 0),
      customerId: Number(this.returnRequestForm.customerId ?? 0),
      productId: this.returnRequestForm.productId ?? null,
      reason: this.returnRequestForm.reason.trim(),
      note: (this.returnRequestForm.note || '').trim(),
      status: this.returnRequestForm.status.trim(),
      requestedAt: this.returnRequestForm.requestedAt,
      updatedAt: this.returnRequestForm.updatedAt
    };

    this.returnRequestService.updateReturnRequest(this.returnRequestId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/returns/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to update return request.';
      }
    });
  }

  onReset(): void {
    this.returnRequestForm = { ...this.initialSnapshot };
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
