import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { OrdersRoutingModule } from './orders-routing.module';

import { OrdersListComponent } from './orders-list/orders-list.component';
import { CartComponent } from './cart/cart.component';
import { CheckoutComponent } from './checkout/checkout.component';
import { CreateOrderComponent } from './create-order/create-order.component';
import { EditOrderComponent } from './edit-order/edit-order.component';
import { DetailsComponent } from './details/details.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [
    OrdersListComponent,
    CartComponent,
    CheckoutComponent,
    CreateOrderComponent,
    EditOrderComponent,
    DetailsComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    OrdersRoutingModule
  ]
})
export class OrdersModule {}
