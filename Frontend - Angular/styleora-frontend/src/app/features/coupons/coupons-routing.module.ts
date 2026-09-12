import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CouponListComponent } from './list/coupon-list.component';
import { CreateCouponComponent } from './create/create-coupon.component';
import { EditCouponComponent } from './edit/edit-coupon.component';
import { CouponDetailsComponent } from './details/coupon-details.component';

const routes: Routes = [
  { path: 'list', component: CouponListComponent },
  { path: 'create', component: CreateCouponComponent },
  { path: 'edit/:id', component: EditCouponComponent },
  { path: 'details/:id', component: CouponDetailsComponent },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CouponsRoutingModule {}
