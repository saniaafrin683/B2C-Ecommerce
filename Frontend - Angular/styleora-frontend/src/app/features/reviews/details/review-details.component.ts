import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Review } from '../review.model';
import { ReviewService } from '../review.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-review-details',
  templateUrl: './review-details.component.html',
  styleUrls: ['./review-details.component.css']
})
export class ReviewDetailsComponent implements OnInit {
  reviewId!: number;
  review: Review | null = null;
  loading = false;
  acting = false;
  savingReply = false;
  errorMessage = '';
  replyMessage = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private reviewService: ReviewService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.reviewId = +id;
        this.loadReview();
      } else {
        this.router.navigate(['/reviews/list']);
      }
    });
  }

  loadReview(): void {
    this.loading = true;
    this.errorMessage = '';

    this.reviewService.getReviewById(this.reviewId).subscribe({
      next: (review) => {
        this.review = review;
        this.replyMessage = review.replyMessage || '';
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load review details.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onApprove(): void {
    if (!this.review) {
      return;
    }

    this.acting = true;
    this.errorMessage = '';
    this.reviewService.approveReview(this.reviewId).subscribe({
      next: (review) => {
        this.review = review;
        this.replyMessage = review.replyMessage || this.replyMessage;
        this.acting = false;
        this.notificationService.showSuccess('Review approved successfully.');
      },
      error: (error) => {
        this.acting = false;
        this.errorMessage = error?.error?.message || 'Failed to approve review.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onReject(): void {
    if (!this.review) {
      return;
    }

    this.acting = true;
    this.errorMessage = '';
    this.reviewService.rejectReview(this.reviewId).subscribe({
      next: (review) => {
        this.review = review;
        this.replyMessage = review.replyMessage || this.replyMessage;
        this.acting = false;
        this.notificationService.showSuccess('Review rejected successfully.');
      },
      error: (error) => {
        this.acting = false;
        this.errorMessage = error?.error?.message || 'Failed to reject review.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onDelete(): void {
    const confirmed = confirm('Are you sure you want to delete this review?');
    if (!confirmed) {
      return;
    }

    this.acting = true;
    this.errorMessage = '';
    this.reviewService.deleteReview(this.reviewId).subscribe({
      next: () => {
        this.acting = false;
        this.notificationService.showSuccess('Review deleted successfully.');
        this.router.navigate(['/reviews/list']);
      },
      error: (error) => {
        this.acting = false;
        this.errorMessage = error?.error?.message || 'Failed to delete review.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onSaveReply(): void {
    if (!this.review) {
      return;
    }

    const replyMessage = (this.replyMessage || '').trim();
    const payload: Review = {
      ...this.review,
      replyMessage,
      reviewStatus: this.review.reviewStatus || 'Pending'
    };

    this.savingReply = true;
    this.errorMessage = '';

    this.reviewService.updateReview(this.reviewId, payload).subscribe({
      next: (review) => {
        this.review = review;
        this.replyMessage = review.replyMessage || '';
        this.savingReply = false;
        this.notificationService.showSuccess('Reply message saved successfully.');
      },
      error: (error) => {
        this.savingReply = false;
        this.errorMessage = error?.error?.message || 'Failed to save reply message.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/reviews/list']);
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('approved')) {
      return 'pill-success';
    }
    if (normalized.includes('rejected')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getStars(rating: number): string {
    const safeRating = Math.min(Math.max(Number(rating || 0), 0), 5);
    return '★'.repeat(safeRating) + '☆'.repeat(5 - safeRating);
  }
}
