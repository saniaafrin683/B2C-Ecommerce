import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SharedModule } from '../../shared/shared.module';
import { ReturnsRoutingModule } from './returns-routing.module';
import { ListReturnRequestComponent } from './list-return-request/list-return-request.component';
import { CreateReturnRequestComponent } from './create-return-request/create-return-request.component';
import { EditReturnRequestComponent } from './edit-return-request/edit-return-request.component';
import { DetailsReturnRequestComponent } from './details-return-request/details-return-request.component';

@NgModule({
  declarations: [
    ListReturnRequestComponent,
    CreateReturnRequestComponent,
    EditReturnRequestComponent,
    DetailsReturnRequestComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    ReturnsRoutingModule
  ]
})
export class ReturnsModule {}
