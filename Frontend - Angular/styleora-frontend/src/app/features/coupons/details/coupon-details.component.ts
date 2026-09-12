import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Coupon } from '../coupon.model';
import { CouponService } from '../coupon.service';
import { SettingsService } from '../../../core/services/settings.service';

@Component({
  selector: 'app-coupon-details',
  templateUrl: './coupon-details.component.html',
  styleUrls: ['./coupon-details.component.css']
})
export class CouponDetailsComponent implements OnInit {
  couponId!: number;
  loading = false;
  errorMessage = '';
  coupon: Coupon | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private couponService: CouponService,
    private settingsService: SettingsService
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
        this.coupon = coupon;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load coupon details.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('active')) {
      return 'pill-success';
    }
    if (normalized.includes('inactive') || normalized.includes('expired')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getDiscountValueLabel(): string {
    if (!this.coupon) {
      return '';
    }

    const type = (this.coupon.discountType || '').toLowerCase();
    if (type.includes('percent')) {
      return `${this.coupon.discountValue}%`;
    }
    return `${this.settingsService.getCurrency()} ${this.coupon.discountValue?.toFixed(2) ?? '0.00'}`;
  }

  onEdit(): void {
    this.router.navigate(['/coupons/edit', this.couponId]);
  }

  onBack(): void {
    this.router.navigate(['/coupons/list']);
  }
}
