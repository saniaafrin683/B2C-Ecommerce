import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { SharedModule } from '../../shared/shared.module';
import { ProductDetailsComponent } from '../products/product-details/product-details.component';
import { ProductDetailsRoutingModule } from './product-details-routing.module';

@NgModule({
  declarations: [ProductDetailsComponent],
  imports: [CommonModule, SharedModule, ProductDetailsRoutingModule]
})
export class ProductDetailsModule {}
