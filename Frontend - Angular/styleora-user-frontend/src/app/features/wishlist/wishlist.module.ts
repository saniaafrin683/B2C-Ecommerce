import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { WishlistRoutingModule } from './wishlist-routing.module';
import { WishlistComponent } from './wishlist.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [WishlistComponent],
  imports: [CommonModule, SharedModule, WishlistRoutingModule]
})
export class WishlistModule {}
