import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SharedModule } from '../../shared/shared.module';
import { ShipmentsRoutingModule } from './shipments-routing.module';
import { ListShipmentComponent } from './list-shipment/list-shipment.component';
import { CreateShipmentComponent } from './create-shipment/create-shipment.component';
import { EditShipmentComponent } from './edit-shipment/edit-shipment.component';
import { DetailsShipmentComponent } from './details-shipment/details-shipment.component';

@NgModule({
  declarations: [
    ListShipmentComponent,
    CreateShipmentComponent,
    EditShipmentComponent,
    DetailsShipmentComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    ShipmentsRoutingModule
  ]
})
export class ShipmentsModule {}
