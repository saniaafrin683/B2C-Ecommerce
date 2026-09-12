import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ReviewListComponent } from './list/review-list.component';
import { ReviewDetailsComponent } from './details/review-details.component';
import { RoleGuard } from '../../core/guards/role.guard';
import { MODERATION_ACCESS_ROLES } from '../../core/auth/admin-role.model';

const routes: Routes = [
  { path: 'list', component: ReviewListComponent, canActivate: [RoleGuard], data: { allowedRoles: MODERATION_ACCESS_ROLES } },
  { path: 'details/:id', component: ReviewDetailsComponent, canActivate: [RoleGuard], data: { allowedRoles: MODERATION_ACCESS_ROLES } },
  { path: '', redirectTo: 'list', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ReviewsRoutingModule {}
