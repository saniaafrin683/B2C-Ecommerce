import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CouponsRoutingModule } from './coupons-routing.module';
import { CouponListComponent } from './list/coupon-list.component';
import { CreateCouponComponent } from './create/create-coupon.component';
import { EditCouponComponent } from './edit/edit-coupon.component';
import { CouponDetailsComponent } from './details/coupon-details.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [
    CouponListComponent,
    CreateCouponComponent,
    EditCouponComponent,
    CouponDetailsComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    CouponsRoutingModule
  ]
})
export class CouponsModule {}
