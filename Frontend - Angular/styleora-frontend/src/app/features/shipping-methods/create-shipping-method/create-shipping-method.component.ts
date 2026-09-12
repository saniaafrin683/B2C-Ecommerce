import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { ShippingMethod } from '../shipping-method.model';
import { ShippingMethodService } from '../shipping-method.service';

@Component({
  selector: 'app-create-shipping-method',
  templateUrl: './create-shipping-method.component.html',
  styleUrls: ['./create-shipping-method.component.css']
})
export class CreateShippingMethodComponent {
  submitting = false;
  errorMessage = '';

  readonly statuses = ['ACTIVE', 'INACTIVE'];
  readonly coverageAreas = ['Inside City', 'Outside City', 'Nationwide', 'International'];
  shippingMethodForm: ShippingMethod = this.createInitialForm();

  constructor(
    private shippingMethodService: ShippingMethodService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.shippingMethodForm.name.trim() || !this.shippingMethodForm.status.trim()) {
      this.errorMessage = 'Name and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: ShippingMethod = {
      ...this.shippingMethodForm,
      name: this.shippingMethodForm.name.trim(),
      description: (this.shippingMethodForm.description || '').trim(),
      coverageArea: (this.shippingMethodForm.coverageArea || '').trim(),
      courierName: (this.shippingMethodForm.courierName || '').trim(),
      cost: Number(this.shippingMethodForm.cost ?? 0),
      minOrderAmount: Number(this.shippingMethodForm.minOrderAmount ?? 0),
      maxWeightKg: Number(this.shippingMethodForm.maxWeightKg ?? 0),
      isFreeShipping: !!this.shippingMethodForm.isFreeShipping,
      estimatedDays: Number(this.shippingMethodForm.estimatedDays ?? 0),
      sortOrder: Number(this.shippingMethodForm.sortOrder ?? 0),
      status: this.shippingMethodForm.status.trim()
    };

    this.shippingMethodService.createShippingMethod(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/shipping-methods/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create shipping method.';
      }
    });
  }

  onReset(): void {
    this.shippingMethodForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/shipping-methods/list']);
  }

  private createInitialForm(): ShippingMethod {
    return {
      id: 0,
      name: '',
      description: '',
      coverageArea: 'Inside City',
      courierName: '',
      cost: 0,
      minOrderAmount: 0,
      maxWeightKg: 0,
      isFreeShipping: false,
      estimatedDays: 1,
      sortOrder: 0,
      status: 'ACTIVE'
    };
  }
}
