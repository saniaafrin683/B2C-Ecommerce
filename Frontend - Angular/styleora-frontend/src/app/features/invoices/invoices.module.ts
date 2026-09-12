import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { InvoicesRoutingModule } from './invoices-routing.module';
import { InvoiceListComponent } from './list/invoice-list.component';
import { InvoiceDetailsComponent } from './details/invoice-details.component';
import { InvoicePrintComponent } from './print/invoice-print.component';
import { CreateInvoiceComponent } from './create/create-invoice.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [
    InvoiceListComponent,
    InvoiceDetailsComponent,
    InvoicePrintComponent,
    CreateInvoiceComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    SharedModule,
    InvoicesRoutingModule
  ]
})
export class InvoicesModule {}
