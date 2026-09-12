import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ReturnRequest } from '../return-request.model';
import { ReturnRequestService } from '../return-request.service';

@Component({
  selector: 'app-list-return-request',
  templateUrl: './list-return-request.component.html',
  styleUrls: ['./list-return-request.component.css']
})
export class ListReturnRequestComponent implements OnInit {
  returnRequests: ReturnRequest[] = [];
  loading = false;
  errorMessage = '';
  updatingId: number | null = null;
  readonly statuses = ['Pending', 'Approved', 'Rejected', 'Refunded'];

  constructor(
    private returnRequestService: ReturnRequestService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadReturnRequests();
  }

  loadReturnRequests(): void {
    this.loading = true;
    this.errorMessage = '';

    this.returnRequestService.getReturnRequests().subscribe({
      next: (returnRequests) => {
        this.returnRequests = returnRequests || [];
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load return requests.';
      }
    });
  }

  onDetails(returnRequest: ReturnRequest): void {
    this.router.navigate(['/returns/details', returnRequest.id]);
  }

  onEdit(returnRequest: ReturnRequest): void {
    this.router.navigate(['/returns/edit', returnRequest.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this return request?');
    if (!confirmed) {
      return;
    }

    this.returnRequestService.deleteReturnRequest(id).subscribe({
      next: () => this.loadReturnRequests(),
      error: () => {
        this.errorMessage = 'Failed to delete return request.';
      }
    });
  }

  onStatusChange(returnRequest: ReturnRequest, status: string): void {
    if (!returnRequest.id || !status || status === returnRequest.status) {
      return;
    }

    this.updatingId = returnRequest.id;
    this.returnRequestService.updateReturnRequestStatus(returnRequest.id, status, returnRequest.note).subscribe({
      next: (updatedRequest) => {
        this.returnRequests = this.returnRequests.map((item) => item.id === updatedRequest.id ? updatedRequest : item);
        this.updatingId = null;
      },
      error: () => {
        this.updatingId = null;
        this.errorMessage = 'Failed to update return request status.';
        this.loadReturnRequests();
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized === 'refunded') {
      return 'pill-success';
    }
    if (normalized === 'rejected') {
      return 'pill-danger';
    }
    if (normalized === 'approved') {
      return 'pill-warning';
    }
    return 'pill-info';
  }
}
