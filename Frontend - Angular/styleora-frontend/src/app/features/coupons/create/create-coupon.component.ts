import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Coupon } from '../coupon.model';
import { CouponService } from '../coupon.service';

@Component({
  selector: 'app-create-coupon',
  templateUrl: './create-coupon.component.html',
  styleUrls: ['./create-coupon.component.css']
})
export class CreateCouponComponent {
  submitting = false;
  errorMessage = '';

  readonly discountTypes = ['Percentage', 'Fixed Amount'];
  readonly statuses = ['Active', 'Inactive', 'Scheduled', 'Expired'];

  couponForm: Coupon = this.createInitialForm();

  constructor(
    private couponService: CouponService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.couponForm.couponCode.trim() ||
        !this.couponForm.discountType.trim() ||
        this.couponForm.discountValue === null ||
        !this.couponForm.startDate ||
        !this.couponForm.endDate ||
        !this.couponForm.status.trim()) {
      this.errorMessage = 'Coupon Code, Discount Type, Discount Value, Start Date, End Date, and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: Coupon = {
      ...this.couponForm,
      couponCode: this.couponForm.couponCode.trim(),
      discountType: this.couponForm.discountType.trim(),
      discountValue: Number(this.couponForm.discountValue ?? 0),
      usageLimit: Number(this.couponForm.usageLimit ?? 0),
      usedCount: Number(this.couponForm.usedCount ?? 0),
      minimumOrderAmount: Number(this.couponForm.minimumOrderAmount ?? 0),
      status: this.couponForm.status.trim(),
      description: (this.couponForm.description || '').trim()
    };

    this.couponService.createCoupon(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/coupons/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create coupon.';
      }
    });
  }

  onReset(): void {
    this.couponForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/coupons/list']);
  }

  private createInitialForm(): Coupon {
    return {
      id: 0,
      couponCode: '',
      discountType: 'Percentage',
      discountValue: 0,
      startDate: '',
      endDate: '',
      usageLimit: 0,
      usedCount: 0,
      minimumOrderAmount: 0,
      status: 'Active',
      description: '',
      createdAt: '',
      updatedAt: ''
    };
  }
}
