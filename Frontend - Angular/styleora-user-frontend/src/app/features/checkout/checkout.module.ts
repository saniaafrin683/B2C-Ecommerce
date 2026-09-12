import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { CheckoutRoutingModule } from './checkout-routing.module';
import { CheckoutComponent } from './checkout.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [CheckoutComponent],
  imports: [CommonModule, FormsModule, SharedModule, CheckoutRoutingModule]
})
export class CheckoutModule {}
