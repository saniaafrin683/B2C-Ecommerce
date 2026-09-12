import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { EmptyStateComponent } from './components/empty-state/empty-state.component';
import { ProductCardComponent } from './components/product-card/product-card.component';
import { ProductGridComponent } from './components/product-grid/product-grid.component';
import { QuantitySelectorComponent } from './components/quantity-selector/quantity-selector.component';

@NgModule({
  declarations: [
    EmptyStateComponent,
    ProductCardComponent,
    ProductGridComponent,
    QuantitySelectorComponent
  ],
  imports: [
    CommonModule,
    RouterModule
  ],
  exports: [
    EmptyStateComponent,
    ProductCardComponent,
    ProductGridComponent,
    QuantitySelectorComponent
  ]
})
export class SharedModule {}
