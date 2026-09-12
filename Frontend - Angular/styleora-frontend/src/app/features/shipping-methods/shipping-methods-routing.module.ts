import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ListShippingMethodComponent } from './list-shipping-method/list-shipping-method.component';
import { CreateShippingMethodComponent } from './create-shipping-method/create-shipping-method.component';
import { EditShippingMethodComponent } from './edit-shipping-method/edit-shipping-method.component';
import { DetailsShippingMethodComponent } from './details-shipping-method/details-shipping-method.component';

const routes: Routes = [
  { path: 'list', component: ListShippingMethodComponent },
  { path: 'create', component: CreateShippingMethodComponent },
  { path: 'edit/:id', component: EditShippingMethodComponent },
  { path: 'details/:id', component: DetailsShippingMethodComponent },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ShippingMethodsRoutingModule {}
