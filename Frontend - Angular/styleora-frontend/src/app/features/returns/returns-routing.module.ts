import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ListReturnRequestComponent } from './list-return-request/list-return-request.component';
import { CreateReturnRequestComponent } from './create-return-request/create-return-request.component';
import { EditReturnRequestComponent } from './edit-return-request/edit-return-request.component';
import { DetailsReturnRequestComponent } from './details-return-request/details-return-request.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { MODERATION_ACCESS_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'list', component: ListReturnRequestComponent, canActivate: [RoleGuard], data: { allowedRoles: MODERATION_ACCESS_ROLES } },
  { path: 'create', component: CreateReturnRequestComponent, canActivate: [RoleGuard], data: { allowedRoles: MODERATION_ACCESS_ROLES } },
  { path: 'edit/:id', component: EditReturnRequestComponent, canActivate: [RoleGuard], data: { allowedRoles: MODERATION_ACCESS_ROLES } },
  { path: 'details/:id', component: DetailsReturnRequestComponent, canActivate: [RoleGuard], data: { allowedRoles: MODERATION_ACCESS_ROLES } },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ReturnsRoutingModule {}
