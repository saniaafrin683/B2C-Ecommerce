import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { OrderDetails, OrderService } from '../../../core/services/order.service';
import { AuthService } from '../../../core/services/auth.service';
import {
  ReviewRecord,
  ReviewService,
  ReviewSubmitPayload
} from '../../../core/services/review.service';
import { ShipmentDetails, ShipmentService } from '../../../core/services/shipment.service';
import {
  ReturnRequest,
  ReturnRequestPayload,
  ReturnRequestService
} from '../../../core/services/return-request.service';

@Component({
  selector: 'app-order-details',
  templateUrl: './order-details.component.html',
  styleUrls: ['./order-details.component.css']
})
export class OrderDetailsComponent implements OnInit {
  private readonly statusTimeline = ['Pending', 'Confirmed', 'Packed', 'Shipped', 'Delivered'];
  private readonly shipmentTimeline = ['Pending', 'Packed', 'Shipped', 'Out For Delivery', 'Delivered'];
  private readonly statusAliases: Record<string, string> = {
    'in progress': 'Packed',
    processing: 'Packed'
  };
  private readonly shipmentStatusAliases: Record<string, string> = {
    created: 'Pending',
    confirmed: 'Packed',
    processing: 'Packed',
    'in progress': 'Packed',
    'in transit': 'Shipped',
    out_for_delivery: 'Out For Delivery'
  };
  readonly companyProfile = {
    name: 'StyleOra',
    tagline: 'Fashion Commerce',
    address: 'House 12, Road 7, Dhanmondi, Dhaka 1205, Bangladesh',
    email: 'support@styleora.com',
    phone: '+880 1710-000000'
  };
  readonly returnReasons = [
    'Damaged Product',
    'Wrong Product',
    'Size Issue',
    'Quality Issue',
    'Other'
  ];
  readonly reviewRatings = [5, 4, 3, 2, 1];

  orderId = '';
  order: OrderDetails | null = null;
  shipment: ShipmentDetails | null = null;
  currentReturnRequest: ReturnRequest | null = null;
  returnStateLoading = false;
  shipmentLoading = false;
  showReturnModal = false;
  submittingReturn = false;
  activeReviewProductId: number | null = null;
  submittingReviewProductId: number | null = null;
  returnSuccessMessage = '';
  returnErrorMessage = '';
  reviewSuccessMessage = '';
  reviewErrorMessage = '';
  returnForm = this.createInitialReturnForm();
  reviewForm = this.createInitialReviewForm();
  existingReviewsByProductId: Record<number, ReviewRecord> = {};

  isLoading = true;
  errorMessage = '';

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly orderService: OrderService,
    private readonly shipmentService: ShipmentService,
    private readonly authService: AuthService,
    private readonly returnRequestService: ReturnRequestService,
    private readonly reviewService: ReviewService
  ) {}

  ngOnInit(): void {
    this.orderId = this.route.snapshot.paramMap.get('id') || '';
    this.loadOrder();
  }

  loadOrder(): void {
    this.isLoading = true;
    const request$ = /^\d+$/.test(this.orderId)
      ? this.orderService.getOrderById(Number(this.orderId))
      : this.orderService.getOrderByReference(this.orderId);

    request$.subscribe({
      next: (order) => {
        this.order = order;
        this.loadReturnRequestState();
        this.loadShipment();
        this.loadReviewState();
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Failed to load order';
        this.isLoading = false;
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/my-orders']);
  }

  get orderItems() {
    return this.order?.orderItems || [];
  }

  get canRequestReturn(): boolean {
    return !!this.order
      && !this.returnStateLoading
      && this.normalizedCurrentStatus === 'delivered'
      && !this.currentReturnRequest;
  }

  get canReviewOrder(): boolean {
    return !!this.order && this.normalizedCurrentStatus === 'delivered';
  }

  get returnStatusLabel(): string {
    if (!this.currentReturnRequest) {
      return '';
    }

    return this.currentReturnRequest.status === 'Pending'
      ? 'Return Requested'
      : `Return ${this.currentReturnRequest.status}`;
  }

  get timelineStatuses(): string[] {
    return this.statusTimeline;
  }

  get normalizedCurrentStatus(): string {
    return this.normalizeStatus(this.order?.orderStatus || 'Pending');
  }

  get shipmentStatuses(): string[] {
    return this.shipmentTimeline;
  }

  get normalizedCurrentShipmentStatus(): string {
    const shipmentStatus = this.shipment?.shipmentStatus || 'Pending';
    return this.normalizeShipmentStatus(shipmentStatus);
  }

  canWriteReview(productId?: number | null): boolean {
    return !!productId && this.canReviewOrder && !this.hasSubmittedReview(productId);
  }

  hasSubmittedReview(productId?: number | null): boolean {
    return !!productId && !!this.existingReviewsByProductId[productId];
  }

  getReviewStatusLabel(productId?: number | null): string {
    if (!productId) {
      return '';
    }

    const review = this.existingReviewsByProductId[productId];
    if (!review) {
      return '';
    }

    const normalizedStatus = (review.reviewStatus || 'Pending').trim().toLowerCase();
    if (normalizedStatus.includes('approved')) {
      return 'Review approved';
    }
    if (normalizedStatus.includes('rejected')) {
      return 'Review rejected';
    }
    return 'Review submitted for approval';
  }

  getStatusIndex(status: string): number {
    const normalizedStatus = this.normalizeStatus(status);
    return this.timelineStatuses.findIndex((item) => this.normalizeStatus(item) === normalizedStatus);
  }

  isCompleted(status: string): boolean {
    const targetIndex = this.getStatusIndex(status);
    const currentIndex = this.getStatusIndex(this.normalizedCurrentStatus);
    return targetIndex !== -1 && currentIndex !== -1 && targetIndex < currentIndex;
  }

  isCurrent(status: string): boolean {
    return this.normalizeStatus(status) === this.normalizedCurrentStatus;
  }

  isInactive(status: string): boolean {
    return !this.isCompleted(status) && !this.isCurrent(status);
  }

  getTimelineIcon(status: string): string {
    if (this.isCompleted(status)) {
      return 'bi-check-lg';
    }

    if (this.isCurrent(status)) {
      return this.normalizeStatus(status) === 'delivered' ? 'bi-bag-check' : 'bi-arrow-repeat';
    }

    switch (this.normalizeStatus(status)) {
      case 'pending':
        return 'bi-receipt';
      case 'confirmed':
        return 'bi-patch-check';
      case 'packed':
        return 'bi-box-seam';
      case 'shipped':
        return 'bi-truck';
      case 'delivered':
        return 'bi-house-check';
      default:
        return 'bi-circle';
    }
  }

  getShipmentStatusIndex(status: string): number {
    const normalizedStatus = this.normalizeShipmentStatus(status);
    return this.shipmentStatuses.findIndex((item) => this.normalizeShipmentStatus(item) === normalizedStatus);
  }

  isShipmentCompleted(status: string): boolean {
    const targetIndex = this.getShipmentStatusIndex(status);
    const currentIndex = this.getShipmentStatusIndex(this.normalizedCurrentShipmentStatus);
    return targetIndex !== -1 && currentIndex !== -1 && targetIndex < currentIndex;
  }

  isShipmentCurrent(status: string): boolean {
    return this.normalizeShipmentStatus(status) === this.normalizedCurrentShipmentStatus;
  }

  isShipmentInactive(status: string): boolean {
    return !this.isShipmentCompleted(status) && !this.isShipmentCurrent(status);
  }

  getShipmentTimelineIcon(status: string): string {
    if (this.isShipmentCompleted(status)) {
      return 'bi-check-lg';
    }

    if (this.isShipmentCurrent(status)) {
      return this.normalizeShipmentStatus(status) === 'delivered' ? 'bi-house-check' : 'bi-truck';
    }

    switch (this.normalizeShipmentStatus(status)) {
      case 'pending':
        return 'bi-receipt-cutoff';
      case 'packed':
        return 'bi-box-seam';
      case 'shipped':
        return 'bi-truck';
      case 'out for delivery':
        return 'bi-geo-alt';
      case 'delivered':
        return 'bi-bag-check';
      default:
        return 'bi-circle';
    }
  }

  getShipmentStatusBadgeClass(): string {
    const status = this.normalizedCurrentShipmentStatus;

    if (status === 'delivered') {
      return 'text-bg-success';
    }

    if (status === 'out for delivery' || status === 'shipped') {
      return 'text-bg-primary';
    }

    if (status === 'packed') {
      return 'text-bg-secondary';
    }

    return 'text-bg-warning';
  }

  getItemOriginalUnitPrice(item: NonNullable<OrderDetails['orderItems']>[number]): number {
    return Number((item.originalUnitPrice ?? item.unitPrice ?? 0).toFixed(2));
  }

  getItemDiscountedUnitPrice(item: NonNullable<OrderDetails['orderItems']>[number]): number {
    return Number((item.discountedUnitPrice ?? item.unitPrice ?? 0).toFixed(2));
  }

  getItemOriginalLineTotal(item: NonNullable<OrderDetails['orderItems']>[number]): number {
    if (typeof item.originalLineTotal === 'number') {
      return Number(item.originalLineTotal.toFixed(2));
    }

    return Number((this.getItemOriginalUnitPrice(item) * (item.quantity || 0)).toFixed(2));
  }

  getItemDiscountedLineTotal(item: NonNullable<OrderDetails['orderItems']>[number]): number {
    return Number((item.lineTotal ?? 0).toFixed(2));
  }

  getItemProductDiscountTotal(item: NonNullable<OrderDetails['orderItems']>[number]): number {
    if (typeof item.productDiscountLineTotal === 'number') {
      return Number(item.productDiscountLineTotal.toFixed(2));
    }

    return Number((this.getItemOriginalLineTotal(item) - this.getItemDiscountedLineTotal(item)).toFixed(2));
  }

  getRegularSubtotal(): number {
    if (typeof this.order?.regularSubtotal === 'number') {
      return Number(this.order.regularSubtotal.toFixed(2));
    }

    return Number(this.orderItems.reduce((total, item) => total + this.getItemOriginalLineTotal(item), 0).toFixed(2));
  }

  getProductDiscountTotal(): number {
    if (typeof this.order?.productDiscountTotal === 'number') {
      return Number(this.order.productDiscountTotal.toFixed(2));
    }

    return Number(this.orderItems.reduce((total, item) => total + this.getItemProductDiscountTotal(item), 0).toFixed(2));
  }

  getSubtotalAfterProductDiscount(): number {
    if (typeof this.order?.subtotalAfterProductDiscount === 'number') {
      return Number(this.order.subtotalAfterProductDiscount.toFixed(2));
    }

    if (typeof this.order?.subtotal === 'number') {
      return Number(this.order.subtotal.toFixed(2));
    }

    return Number(this.orderItems.reduce((total, item) => total + this.getItemDiscountedLineTotal(item), 0).toFixed(2));
  }

  getCouponDiscount(): number {
    if (typeof this.order?.couponDiscount === 'number') {
      return Number(this.order.couponDiscount.toFixed(2));
    }

    return Number((this.order?.discount || 0).toFixed(2));
  }

  getDisplayInvoiceNumber(): string {
    const orderReference = this.order?.orderId || this.orderId || '';
    const safeReference = orderReference.replace(/[^A-Za-z0-9]/g, '');
    return safeReference ? `INV-${safeReference}` : `INV-${this.order?.id || '0000'}`;
  }

  getCustomerAddress(): string {
    return this.order?.billingAddress || this.order?.shippingAddress || 'Address not provided';
  }

  getCustomerLocation(): string {
    return 'City/Country not available';
  }

  printInvoice(): void {
    window.print();
  }

  hasShipment(): boolean {
    return !!this.shipment;
  }

  openReturnModal(): void {
    if (!this.canRequestReturn) {
      return;
    }

    this.returnForm = this.createInitialReturnForm();
    this.returnErrorMessage = '';
    this.returnSuccessMessage = '';
    this.showReturnModal = true;
  }

  closeReturnModal(): void {
    this.showReturnModal = false;
    this.submittingReturn = false;
    this.returnErrorMessage = '';
  }

  openReviewForm(productId: number): void {
    if (!this.canWriteReview(productId)) {
      return;
    }

    this.activeReviewProductId = productId;
    this.reviewForm = this.createInitialReviewForm();
    this.reviewSuccessMessage = '';
    this.reviewErrorMessage = '';
  }

  closeReviewForm(): void {
    this.activeReviewProductId = null;
    this.submittingReviewProductId = null;
    this.reviewErrorMessage = '';
    this.reviewForm = this.createInitialReviewForm();
  }

  submitReturnRequest(): void {
    if (!this.order?.id) {
      return;
    }

    const customer = this.authService.getCustomerSnapshot();
    if (!customer?.id) {
      this.returnErrorMessage = 'Customer profile is required to submit a return request.';
      return;
    }

    if (!this.returnForm.reason.trim()) {
      this.returnErrorMessage = 'Please select a return reason.';
      return;
    }

    const payload: ReturnRequestPayload = {
      orderId: this.order.id,
      customerId: customer.id,
      reason: this.returnForm.reason.trim(),
      note: this.returnForm.note.trim()
    };

    this.submittingReturn = true;
    this.returnErrorMessage = '';

    this.returnRequestService.requestReturn(payload).subscribe({
      next: (returnRequest) => {
        this.currentReturnRequest = returnRequest;
        this.returnSuccessMessage = 'Return request submitted successfully.';
        this.submittingReturn = false;
        this.showReturnModal = false;
      },
      error: (error) => {
        this.submittingReturn = false;
        this.returnErrorMessage = error?.error?.message || 'Failed to submit return request.';
      }
    });
  }

  submitReview(productId: number): void {
    if (!this.order?.id || !this.canWriteReview(productId)) {
      return;
    }

    const comment = this.reviewForm.comment.trim();
    if (!this.reviewForm.rating || this.reviewForm.rating < 1 || this.reviewForm.rating > 5) {
      this.reviewErrorMessage = 'Please select a rating between 1 and 5.';
      return;
    }

    if (!comment) {
      this.reviewErrorMessage = 'Please write a short review comment.';
      return;
    }

    const payload: ReviewSubmitPayload = {
      orderId: this.order.id,
      productId,
      rating: this.reviewForm.rating,
      comment
    };

    this.submittingReviewProductId = productId;
    this.reviewErrorMessage = '';
    this.reviewSuccessMessage = '';

    this.reviewService.submitReview(payload).subscribe({
      next: (review) => {
        this.existingReviewsByProductId[productId] = review;
        this.reviewSuccessMessage = 'Review submitted for approval.';
        this.submittingReviewProductId = null;
        this.activeReviewProductId = null;
        this.reviewForm = this.createInitialReviewForm();
      },
      error: (error) => {
        this.submittingReviewProductId = null;
        this.reviewErrorMessage = error?.error?.message || 'Failed to submit review.';
      }
    });
  }

  private normalizeStatus(status: string): string {
    const rawStatus = (status || 'Pending').trim().toLowerCase();
    const mappedStatus = this.statusAliases[rawStatus] || status || 'Pending';
    return mappedStatus.trim().toLowerCase();
  }

  private normalizeShipmentStatus(status: string): string {
    const rawStatus = (status || 'Pending').trim().toLowerCase();
    const mappedStatus = this.shipmentStatusAliases[rawStatus] || status || 'Pending';
    return mappedStatus.trim().toLowerCase();
  }

  private loadShipment(): void {
    if (!this.order?.id) {
      this.shipment = null;
      this.shipmentLoading = false;
      return;
    }

    this.shipmentLoading = true;
    this.shipmentService.getShipmentByOrderId(this.order.id).subscribe({
      next: (shipment) => {
        this.shipment = shipment;
        this.shipmentLoading = false;
      },
      error: () => {
        this.shipment = null;
        this.shipmentLoading = false;
      }
    });
  }

  private loadReturnRequestState(): void {
    const customer = this.authService.getCustomerSnapshot();
    if (!customer?.id || !this.order?.id) {
      this.currentReturnRequest = null;
      this.returnStateLoading = false;
      return;
    }

    this.returnStateLoading = true;
    this.returnRequestService.getCustomerReturnRequests(customer.id).subscribe({
      next: (requests) => {
        this.currentReturnRequest = requests.find((item) => item.orderId === this.order?.id) || null;
        this.returnStateLoading = false;
      },
      error: () => {
        this.currentReturnRequest = null;
        this.returnStateLoading = false;
      }
    });
  }

  private loadReviewState(): void {
    if (!this.order?.id || !this.canReviewOrder || !this.authService.getCustomerSnapshot()?.id) {
      this.existingReviewsByProductId = {};
      this.activeReviewProductId = null;
      return;
    }

    this.reviewService.getMyReviewsForOrder(this.order.id).subscribe({
      next: (reviews) => {
        this.existingReviewsByProductId = (reviews || []).reduce<Record<number, ReviewRecord>>((accumulator, review) => {
          if (review.productId) {
            accumulator[review.productId] = review;
          }
          return accumulator;
        }, {});
      },
      error: () => {
        this.existingReviewsByProductId = {};
      }
    });
  }

  private createInitialReturnForm(): { reason: string; note: string } {
    return {
      reason: '',
      note: ''
    };
  }

  private createInitialReviewForm(): { rating: number; comment: string } {
    return {
      rating: 5,
      comment: ''
    };
  }
}
