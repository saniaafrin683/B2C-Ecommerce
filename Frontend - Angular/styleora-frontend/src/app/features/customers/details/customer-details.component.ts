import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Customer } from '../customer.model';
import { CustomerService } from '../customer.service';

@Component({
  selector: 'app-customer-details',
  templateUrl: './customer-details.component.html',
  styleUrls: ['./customer-details.component.css']
})
export class CustomerDetailsComponent implements OnInit {
  customerId!: number;
  loading = false;
  errorMessage = '';
  customer: Customer | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private customerService: CustomerService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.customerId = +id;
        this.loadCustomer();
      } else {
        this.router.navigate(['/customers/list']);
      }
    });
  }

  loadCustomer(): void {
    this.loading = true;
    this.errorMessage = '';

    this.customerService.getCustomerById(this.customerId).subscribe({
      next: (customer) => {
        this.customer = customer;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load customer details.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('active')) {
      return 'pill-success';
    }
    if (normalized.includes('inactive') || normalized.includes('blocked')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getInitials(name: string): string {
    if (!name) {
      return 'CU';
    }

    return name
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map(part => part.charAt(0).toUpperCase())
      .join('');
  }

  onEdit(): void {
    this.router.navigate(['/customers/edit', this.customerId]);
  }

  onBack(): void {
    this.router.navigate(['/customers/list']);
  }
}
