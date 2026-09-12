import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Review } from '../review.model';
import { ReviewService } from '../review.service';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';

@Component({
  selector: 'app-review-list',
  templateUrl: './review-list.component.html',
  styleUrls: ['./review-list.component.css']
})
export class ReviewListComponent implements OnInit {
  reviews: Review[] = [];
  paginatedReviews: Review[] = [];
  loading = false;
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 10;

  constructor(
    private reviewService: ReviewService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadReviews();
  }

  get totalReviews(): number {
    return this.reviews.length;
  }

  get pendingReviews(): number {
    return this.reviews.filter((review) => this.isPending(review.reviewStatus)).length;
  }

  get approvedReviews(): number {
    return this.reviews.filter((review) => this.isApproved(review.reviewStatus)).length;
  }

  get rejectedReviews(): number {
    return this.reviews.filter((review) => this.isRejected(review.reviewStatus)).length;
  }

  loadReviews(): void {
    this.loading = true;
    this.errorMessage = '';

    this.reviewService.getReviews().subscribe({
      next: (reviews) => {
        this.reviews = reviews || [];
        this.currentPage = 1;
        this.updatePaginatedReviews();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load reviews.';
      }
    });
  }

  onView(review: Review): void {
    this.router.navigate(['/reviews/details', review.id]);
  }

  onApprove(review: Review): void {
    this.reviewService.approveReview(review.id).subscribe({
      next: () => this.loadReviews(),
      error: () => {
        this.errorMessage = 'Failed to approve review.';
      }
    });
  }

  onReject(review: Review): void {
    this.reviewService.rejectReview(review.id).subscribe({
      next: () => this.loadReviews(),
      error: () => {
        this.errorMessage = 'Failed to reject review.';
      }
    });
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this review?');
    if (!confirmed) {
      return;
    }

    this.reviewService.deleteReview(id).subscribe({
      next: () => this.loadReviews(),
      error: () => {
        this.errorMessage = 'Failed to delete review.';
      }
    });
  }

  getStatusClass(status: string): string {
    if (this.isApproved(status)) {
      return 'pill-success';
    }
    if (this.isRejected(status)) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getInitials(name: string): string {
    if (!name) {
      return 'NA';
    }

    return name
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part.charAt(0).toUpperCase())
      .join('');
  }

  getStars(rating: number): string {
    const safeRating = Math.min(Math.max(Number(rating || 0), 0), 5);
    return '★'.repeat(safeRating) + '☆'.repeat(5 - safeRating);
  }

  private isApproved(status: string): boolean {
    return (status || '').toLowerCase().includes('approved');
  }

  private isRejected(status: string): boolean {
    return (status || '').toLowerCase().includes('rejected');
  }

  private isPending(status: string): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('pending') || (!this.isApproved(status) && !this.isRejected(status));
  }

  get totalPages(): number {
    return getTotalPages(this.reviews.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedReviews();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedReviews(): void {
    this.paginatedReviews = getPaginatedItems(this.reviews, this.currentPage, this.pageSize);
  }
}
