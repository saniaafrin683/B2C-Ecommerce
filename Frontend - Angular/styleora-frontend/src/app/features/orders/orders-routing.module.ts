import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { RoleGuard } from '../../core/guards/role.guard';
import { ORDER_MANAGE_ROLES, ORDER_VIEW_ROLES } from '../../core/auth/admin-role.model';

import { OrdersListComponent } from './orders-list/orders-list.component';
import { CreateOrderComponent } from './create-order/create-order.component';
import { EditOrderComponent } from './edit-order/edit-order.component';
import { DetailsComponent } from './details/details.component';

const routes: Routes = [
  { path: '', redirectTo: 'list', pathMatch: 'full' },
  { path: 'list', component: OrdersListComponent, canActivate: [RoleGuard], data: { allowedRoles: ORDER_VIEW_ROLES } },
  { path: 'cart', redirectTo: 'list', pathMatch: 'full' },
  { path: 'checkout', redirectTo: 'list', pathMatch: 'full' },
  { path: 'create', component: CreateOrderComponent, canActivate: [RoleGuard], data: { allowedRoles: ORDER_MANAGE_ROLES } },
  { path: 'edit/:id', component: EditOrderComponent, canActivate: [RoleGuard], data: { allowedRoles: ORDER_MANAGE_ROLES } },
  { path: 'details/:id', component: DetailsComponent, canActivate: [RoleGuard], data: { allowedRoles: ORDER_VIEW_ROLES } }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class OrdersRoutingModule {}
