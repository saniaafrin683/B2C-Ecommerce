import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HotDealComponent } from './hot-deal/hot-deal.component';

const routes: Routes = [
  { path: '', component: HotDealComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class HotDealRoutingModule {}