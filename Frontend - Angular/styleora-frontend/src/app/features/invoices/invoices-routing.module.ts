import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { InvoiceListComponent } from './list/invoice-list.component';
import { InvoiceDetailsComponent } from './details/invoice-details.component';
import { InvoicePrintComponent } from './print/invoice-print.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { SALES_ACCESS_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'list', component: InvoiceListComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'create', redirectTo: 'list', pathMatch: 'full' },
  { path: 'details/:id', component: InvoiceDetailsComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'print/:id', component: InvoicePrintComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class InvoicesRoutingModule {}
