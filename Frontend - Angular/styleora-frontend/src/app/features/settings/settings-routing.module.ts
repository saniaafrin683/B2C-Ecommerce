import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { GeneralSettingsComponent } from './general/general-settings.component';

const routes: Routes = [
  { path: 'general', component: GeneralSettingsComponent },
  { path: '', redirectTo: 'general', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class SettingsRoutingModule {}
