import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { PaymentListComponent } from './list/payment-list.component';
import { CreatePaymentComponent } from './create/create-payment.component';
import { EditPaymentComponent } from './edit/edit-payment.component';
import { PaymentDetailsComponent } from './details/payment-details.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { SALES_ACCESS_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'list', component: PaymentListComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'create', component: CreatePaymentComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'edit/:id', component: EditPaymentComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'details/:id', component: PaymentDetailsComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class PaymentsRoutingModule {}
