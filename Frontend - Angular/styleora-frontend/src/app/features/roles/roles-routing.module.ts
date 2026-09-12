import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ListRoleComponent } from './list-role/list-role.component';
import { CreateRoleComponent } from './create-role/create-role.component';
import { EditRoleComponent } from './edit-role/edit-role.component';
import { DetailsRoleComponent } from './details-role/details-role.component';

const routes: Routes = [
  { path: 'list', component: ListRoleComponent },
  { path: 'create', component: CreateRoleComponent },
  { path: 'edit/:id', component: EditRoleComponent },
  { path: 'details/:id', component: DetailsRoleComponent },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class RolesRoutingModule {}
