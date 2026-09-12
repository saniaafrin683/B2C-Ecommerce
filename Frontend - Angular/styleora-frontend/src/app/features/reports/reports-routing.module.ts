import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ReportsDashboardComponent } from './dashboard/reports-dashboard.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { DASHBOARD_ACCESS_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'dashboard', component: ReportsDashboardComponent, canActivate: [RoleGuard], data: { allowedRoles: DASHBOARD_ACCESS_ROLES } },
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ReportsRoutingModule {}
