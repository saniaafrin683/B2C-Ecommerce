import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ReviewsRoutingModule } from './reviews-routing.module';
import { ReviewListComponent } from './list/review-list.component';
import { ReviewDetailsComponent } from './details/review-details.component';

@NgModule({
  declarations: [
    ReviewListComponent,
    ReviewDetailsComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReviewsRoutingModule
  ]
})
export class ReviewsModule {}
