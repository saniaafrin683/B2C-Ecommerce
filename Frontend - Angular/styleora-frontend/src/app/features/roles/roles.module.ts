import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RolesRoutingModule } from './roles-routing.module';
import { ListRoleComponent } from './list-role/list-role.component';
import { CreateRoleComponent } from './create-role/create-role.component';
import { EditRoleComponent } from './edit-role/edit-role.component';
import { DetailsRoleComponent } from './details-role/details-role.component';

@NgModule({
  declarations: [
    ListRoleComponent,
    CreateRoleComponent,
    EditRoleComponent,
    DetailsRoleComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    RolesRoutingModule
  ]
})
export class RolesModule {}
