import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Payment } from '../payment.model';
import { PaymentService } from '../payment.service';

@Component({
  selector: 'app-payment-details',
  templateUrl: './payment-details.component.html',
  styleUrls: ['./payment-details.component.css']
})
export class PaymentDetailsComponent implements OnInit {
  paymentId!: number;
  payment: Payment | null = null;
  loading = false;
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private paymentService: PaymentService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.paymentId = +id;
        this.loadPayment();
      } else {
        this.router.navigate(['/payments/list']);
      }
    });
  }

  loadPayment(): void {
    this.loading = true;
    this.errorMessage = '';

    this.paymentService.getPaymentById(this.paymentId).subscribe({
      next: (payment) => {
        this.payment = payment;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load payment details.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('paid') || normalized.includes('completed') || normalized.includes('success')) {
      return 'pill-success';
    }
    if (normalized.includes('failed') || normalized.includes('cancel') || normalized.includes('declined')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  onEdit(): void {
    this.router.navigate(['/payments/edit', this.paymentId]);
  }

  onBack(): void {
    this.router.navigate(['/payments/list']);
  }
}
