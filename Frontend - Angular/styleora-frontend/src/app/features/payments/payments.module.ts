import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PaymentsRoutingModule } from './payments-routing.module';
import { PaymentListComponent } from './list/payment-list.component';
import { CreatePaymentComponent } from './create/create-payment.component';
import { EditPaymentComponent } from './edit/edit-payment.component';
import { PaymentDetailsComponent } from './details/payment-details.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [
    PaymentListComponent,
    CreatePaymentComponent,
    EditPaymentComponent,
    PaymentDetailsComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    PaymentsRoutingModule
  ]
})
export class PaymentsModule {}
