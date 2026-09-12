import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ListShipmentComponent } from './list-shipment/list-shipment.component';
import { CreateShipmentComponent } from './create-shipment/create-shipment.component';
import { EditShipmentComponent } from './edit-shipment/edit-shipment.component';
import { DetailsShipmentComponent } from './details-shipment/details-shipment.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { SALES_ACCESS_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'list', component: ListShipmentComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'create', component: CreateShipmentComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'edit/:id', component: EditShipmentComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: 'details/:id', component: DetailsShipmentComponent, canActivate: [RoleGuard], data: { allowedRoles: SALES_ACCESS_ROLES } },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ShipmentsRoutingModule {}
