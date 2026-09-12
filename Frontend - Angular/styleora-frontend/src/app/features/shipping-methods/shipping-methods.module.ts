import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SharedModule } from '../../shared/shared.module';
import { ShippingMethodsRoutingModule } from './shipping-methods-routing.module';
import { ListShippingMethodComponent } from './list-shipping-method/list-shipping-method.component';
import { CreateShippingMethodComponent } from './create-shipping-method/create-shipping-method.component';
import { EditShippingMethodComponent } from './edit-shipping-method/edit-shipping-method.component';
import { DetailsShippingMethodComponent } from './details-shipping-method/details-shipping-method.component';

@NgModule({
  declarations: [
    ListShippingMethodComponent,
    CreateShippingMethodComponent,
    EditShippingMethodComponent,
    DetailsShippingMethodComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    ShippingMethodsRoutingModule
  ]
})
export class ShippingMethodsModule {}
