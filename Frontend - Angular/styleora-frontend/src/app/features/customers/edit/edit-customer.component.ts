import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Customer } from '../customer.model';
import { CustomerService } from '../customer.service';

@Component({
  selector: 'app-edit-customer',
  templateUrl: './edit-customer.component.html',
  styleUrls: ['./edit-customer.component.css']
})
export class EditCustomerComponent implements OnInit {
  customerId!: number;
  loading = false;
  submitting = false;
  errorMessage = '';

  readonly genders = ['MALE', 'FEMALE', 'OTHER'];
  readonly statuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

  customerForm: Customer = this.createInitialForm();

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
        this.customerForm = customer;
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load customer', err);
        this.loading = false;
        this.errorMessage = err?.error?.message || err?.message || 'Failed to load customer.';
      }
    });
  }

  onUpdate(): void {
    this.errorMessage = '';

    if (!this.customerForm.customerCode.trim() ||
        !this.customerForm.fullName.trim() ||
        !this.customerForm.email.trim() ||
        !this.customerForm.status.trim()) {
      this.errorMessage = 'Customer Code, Full Name, Email, and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: Customer = {
      ...this.customerForm,
      customerCode: this.customerForm.customerCode.trim(),
      fullName: this.customerForm.fullName.trim(),
      email: this.customerForm.email.trim(),
      phone: (this.customerForm.phone || '').trim(),
      gender: (this.customerForm.gender || '').trim().toUpperCase(),
      address: (this.customerForm.address || '').trim(),
      city: (this.customerForm.city || '').trim(),
      country: (this.customerForm.country || '').trim(),
      totalOrders: Number(this.customerForm.totalOrders ?? 0),
      totalSpend: Number(this.customerForm.totalSpend ?? 0),
      status: this.customerForm.status.trim().toUpperCase(),
      notes: (this.customerForm.notes || '').trim()
    };

    this.customerService.updateCustomer(this.customerId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/customers/list']);
      },
      error: (err) => {
        console.error('Failed to update customer', err);
        this.submitting = false;
        this.errorMessage = err?.error?.message || err?.message || 'Failed to update customer.';
      }
    });
  }

  onReset(): void {
    this.loadCustomer();
  }

  onCancel(): void {
    this.router.navigate(['/customers/list']);
  }

  private createInitialForm(): Customer {
    return {
      id: 0,
      customerCode: '',
      fullName: '',
      email: '',
      phone: '',
      gender: 'MALE',
      dateOfBirth: '',
      address: '',
      city: '',
      country: '',
      totalOrders: 0,
      totalSpend: 0,
      status: 'ACTIVE',
      registeredAt: '',
      notes: ''
    };
  }
}
