import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CustomerListComponent } from './list/customer-list.component';
import { CreateCustomerComponent } from './create/create-customer.component';
import { EditCustomerComponent } from './edit/edit-customer.component';
import { CustomerDetailsComponent } from './details/customer-details.component';
import { RestoreCustomersComponent } from './restore/restore-customers.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { ADMIN_ONLY_ROLES, CUSTOMER_VIEW_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'list', component: CustomerListComponent, canActivate: [RoleGuard], data: { allowedRoles: CUSTOMER_VIEW_ROLES } },
  { path: 'create', component: CreateCustomerComponent, canActivate: [RoleGuard], data: { allowedRoles: ADMIN_ONLY_ROLES } },
  { path: 'restore', component: RestoreCustomersComponent, canActivate: [RoleGuard], data: { allowedRoles: ADMIN_ONLY_ROLES } },
  { path: 'edit/:id', component: EditCustomerComponent, canActivate: [RoleGuard], data: { allowedRoles: ADMIN_ONLY_ROLES } },
  { path: 'details/:id', component: CustomerDetailsComponent, canActivate: [RoleGuard], data: { allowedRoles: CUSTOMER_VIEW_ROLES } },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CustomersRoutingModule {}
