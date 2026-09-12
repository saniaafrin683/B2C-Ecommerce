import { Component, OnInit } from '@angular/core';
import { ReviewRecord, ReviewService } from '../../core/services/review.service';

@Component({
  selector: 'app-my-reviews',
  templateUrl: './my-reviews.component.html',
  styleUrls: ['./my-reviews.component.css']
})
export class MyReviewsComponent implements OnInit {
  reviews: ReviewRecord[] = [];
  isLoading = true;
  errorMessage = '';

  constructor(private readonly reviewService: ReviewService) {}

  ngOnInit(): void {
    this.reviewService.getMyReviews().subscribe({
      next: (reviews) => {
        this.reviews = reviews || [];
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Unable to load your reviews right now.';
        this.isLoading = false;
      }
    });
  }

  getStatusClass(status: string | undefined): string {
    const normalizedStatus = (status || 'Pending').trim().toLowerCase();

    if (normalizedStatus.includes('approved')) {
      return 'status-success';
    }
    if (normalizedStatus.includes('rejected')) {
      return 'status-danger';
    }
    return 'status-warning';
  }

  trackByReview(index: number, review: ReviewRecord): number {
    return review.id || index;
  }
}
