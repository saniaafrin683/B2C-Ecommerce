import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CustomersRoutingModule } from './customers-routing.module';
import { CustomerListComponent } from './list/customer-list.component';
import { CreateCustomerComponent } from './create/create-customer.component';
import { EditCustomerComponent } from './edit/edit-customer.component';
import { CustomerDetailsComponent } from './details/customer-details.component';
import { SharedModule } from '../../shared/shared.module';
import { RestoreCustomersComponent } from './restore/restore-customers.component';

@NgModule({
  declarations: [
    CustomerListComponent,
    CreateCustomerComponent,
    EditCustomerComponent,
    CustomerDetailsComponent,
    RestoreCustomersComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    CustomersRoutingModule
  ]
})
export class CustomersModule {}
