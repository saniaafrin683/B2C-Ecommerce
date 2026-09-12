import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { HotDealRoutingModule } from './hot-deal-routing.module';
import { HotDealComponent } from './hot-deal/hot-deal.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [
    HotDealComponent
  ],
  imports: [
    CommonModule,
    HotDealRoutingModule,
    SharedModule   // ✅ MUST ADD
  ]
})
export class HotDealModule { }