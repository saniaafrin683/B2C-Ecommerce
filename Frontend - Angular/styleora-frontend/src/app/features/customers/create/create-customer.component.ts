import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Customer } from '../customer.model';
import { CustomerService } from '../customer.service';

@Component({
  selector: 'app-create-customer',
  templateUrl: './create-customer.component.html',
  styleUrls: ['./create-customer.component.css']
})
export class CreateCustomerComponent {
  submitting = false;
  errorMessage = '';

  readonly genders = ['MALE', 'FEMALE', 'OTHER'];
  readonly statuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

  customerForm: Customer = this.createInitialForm();

  constructor(
    private customerService: CustomerService,
    private router: Router
  ) {}

  onSave(): void {
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

    this.customerService.createCustomer(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/customers/list']);
      },
      error: (err) => {
        console.error('Failed to create customer', err);
        this.submitting = false;
        this.errorMessage = err?.error?.message || err?.message || 'Failed to create customer.';
      }
    });
  }

  onReset(): void {
    this.customerForm = this.createInitialForm();
    this.errorMessage = '';
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
