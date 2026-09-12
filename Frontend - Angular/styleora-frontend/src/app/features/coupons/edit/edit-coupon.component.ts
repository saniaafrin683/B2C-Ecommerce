import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Coupon } from '../coupon.model';
import { CouponService } from '../coupon.service';

@Component({
  selector: 'app-edit-coupon',
  templateUrl: './edit-coupon.component.html',
  styleUrls: ['./edit-coupon.component.css']
})
export class EditCouponComponent implements OnInit {
  couponId!: number;
  loading = false;
  submitting = false;
  errorMessage = '';

  readonly discountTypes = ['Percentage', 'Fixed Amount'];
  readonly statuses = ['Active', 'Inactive', 'Scheduled', 'Expired'];

  couponForm: Coupon = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private couponService: CouponService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.couponId = +id;
        this.loadCoupon();
      } else {
        this.router.navigate(['/coupons/list']);
      }
    });
  }

  loadCoupon(): void {
    this.loading = true;
    this.errorMessage = '';

    this.couponService.getCouponById(this.couponId).subscribe({
      next: (coupon) => {
        this.couponForm = coupon;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load coupon.';
      }
    });
  }

  onUpdate(): void {
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

    this.couponService.updateCoupon(this.couponId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/coupons/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to update coupon.';
      }
    });
  }

  onReset(): void {
    this.loadCoupon();
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
