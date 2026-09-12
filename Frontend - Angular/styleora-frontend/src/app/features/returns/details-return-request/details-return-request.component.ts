import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ReturnRequest } from '../return-request.model';
import { ReturnRequestService } from '../return-request.service';

@Component({
  selector: 'app-details-return-request',
  templateUrl: './details-return-request.component.html',
  styleUrls: ['./details-return-request.component.css']
})
export class DetailsReturnRequestComponent implements OnInit {
  returnRequestId!: number;
  loading = false;
  errorMessage = '';
  returnRequest: ReturnRequest | null = null;

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
        this.returnRequest = returnRequest;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load return request details.';
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/returns/list']);
  }

  onEdit(): void {
    this.router.navigate(['/returns/edit', this.returnRequestId]);
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
