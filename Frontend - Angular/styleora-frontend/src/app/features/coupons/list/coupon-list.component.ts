import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Coupon } from '../coupon.model';
import { CouponService } from '../coupon.service';
import { SettingsService } from '../../../core/services/settings.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-coupon-list',
  templateUrl: './coupon-list.component.html',
  styleUrls: ['./coupon-list.component.css']
})
export class CouponListComponent implements OnInit {
  coupons: Coupon[] = [];
  paginatedCoupons: Coupon[] = [];
  loading = false;
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 10;
  readonly packageCards = [
    {
      title: 'Summer Promo Pack',
      subtitle: 'Small nice summer coupons pack',
      duration: '1 Year',
      accent: 'accent-primary'
    },
    {
      title: 'Flash Deal Bundle',
      subtitle: 'Fast moving discount bundle for campaigns',
      duration: '6 Months',
      accent: 'accent-success'
    },
    {
      title: 'Member Reward Set',
      subtitle: 'Retention-focused codes for loyal customers',
      duration: '3 Months',
      accent: 'accent-warning'
    }
  ];

  constructor(
    private couponService: CouponService,
    private settingsService: SettingsService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCoupons();
  }

  loadCoupons(): void {
    this.loading = true;
    this.errorMessage = '';

    this.couponService.getCoupons().subscribe({
      next: (coupons) => {
        this.coupons = coupons || [];
        this.currentPage = 1;
        this.updatePaginatedCoupons();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load coupons.';
      }
    });
  }

  onCreate(): void {
    this.router.navigate(['/coupons/create']);
  }

  onView(coupon: Coupon): void {
    this.router.navigate(['/coupons/details', coupon.id]);
  }

  onEdit(coupon: Coupon): void {
    this.router.navigate(['/coupons/edit', coupon.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this coupon?');
    if (!confirmed) {
      return;
    }

    this.couponService.deleteCoupon(id).subscribe({
      next: () => {
        this.loadCoupons();
      },
      error: () => {
        this.errorMessage = 'Failed to delete coupon.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = this.getNormalizedStatus(status);
    if (normalized === 'ACTIVE') {
      return 'pill-success';
    }
    if (normalized === 'EXPIRED') {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getDiscountValueLabel(coupon: Coupon): string {
    const type = (coupon.discountType || '').toLowerCase();
    if (type.includes('percent')) {
      return `${coupon.discountValue}%`;
    }
    return `${this.settingsService.getCurrency()} ${coupon.discountValue?.toFixed(2) ?? '0.00'}`;
  }

  getTotalCoupons(): number {
    return this.coupons.length;
  }

  getActiveCoupons(): number {
    return this.coupons.filter(coupon => this.getNormalizedStatus(coupon.status) === 'ACTIVE').length;
  }

  getExpiredCoupons(): number {
    return this.coupons.filter(coupon => this.getNormalizedStatus(coupon.status) === 'EXPIRED').length;
  }

  getInactiveCoupons(): number {
    return this.coupons.filter(coupon => this.getNormalizedStatus(coupon.status) === 'INACTIVE').length;
  }

  getPackageCouponCount(index: number): number {
    if (this.coupons.length === 0) {
      return index + 2;
    }
    return Math.max(1, Math.min(this.coupons.length, index + 2));
  }

  getPackageValue(index: number): string {
    const coupon = this.coupons[index];
    if (coupon) {
      return this.getDiscountValueLabel(coupon);
    }
    return `${this.settingsService.getCurrency()} ${(index + 1) * 250}`;
  }

  getPromoDateRange(): string {
    if (this.coupons.length === 0) {
      return '01 Jan 2026 - 31 Dec 2026';
    }

    const startDates = this.coupons
      .map(coupon => new Date(coupon.startDate))
      .filter(date => !isNaN(date.getTime()))
      .sort((a, b) => a.getTime() - b.getTime());

    const endDates = this.coupons
      .map(coupon => new Date(coupon.endDate))
      .filter(date => !isNaN(date.getTime()))
      .sort((a, b) => b.getTime() - a.getTime());

    if (startDates.length === 0 || endDates.length === 0) {
      return 'Campaign timeline unavailable';
    }

    return `${this.formatShortDate(startDates[0])} - ${this.formatShortDate(endDates[0])}`;
  }

  getProductName(coupon: Coupon): string {
    return coupon.description?.trim() || 'All Products';
  }

  getProductType(coupon: Coupon): string {
    const type = (coupon.discountType || '').toLowerCase();
    if (type.includes('percent')) {
      return 'Fashion';
    }
    if (type.includes('flat')) {
      return 'Voucher';
    }
    return 'General';
  }

  getPriceLabel(coupon: Coupon): string {
    if (coupon.minimumOrderAmount && coupon.minimumOrderAmount > 0) {
      return `${this.settingsService.getCurrency()} ${coupon.minimumOrderAmount.toFixed(2)}`;
    }
    return 'N/A';
  }

  getThumbnailLabel(coupon: Coupon): string {
    return (coupon.couponCode || 'CP').slice(0, 2).toUpperCase();
  }

  private getNormalizedStatus(status: string): string {
    const normalized = (status || '').trim().toUpperCase();
    if (normalized.includes('EXPIRED')) {
      return 'EXPIRED';
    }
    if (normalized.includes('INACTIVE') || normalized.includes('DRAFT')) {
      return 'INACTIVE';
    }
    if (normalized.includes('ACTIVE')) {
      return 'ACTIVE';
    }
    return normalized || 'INACTIVE';
  }

  private formatShortDate(date: Date): string {
    return new Intl.DateTimeFormat('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    }).format(date);
  }

  get totalPages(): number {
    return getTotalPages(this.coupons.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedCoupons();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedCoupons(): void {
    this.paginatedCoupons = getPaginatedItems(this.coupons, this.currentPage, this.pageSize);
  }
}
