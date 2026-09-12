import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SharedModule } from '../../shared/shared.module';
import { MyReviewsRoutingModule } from './my-reviews-routing.module';
import { MyReviewsComponent } from './my-reviews.component';

@NgModule({
  declarations: [MyReviewsComponent],
  imports: [
    CommonModule,
    RouterModule,
    SharedModule,
    MyReviewsRoutingModule
  ]
})
export class MyReviewsModule {}
