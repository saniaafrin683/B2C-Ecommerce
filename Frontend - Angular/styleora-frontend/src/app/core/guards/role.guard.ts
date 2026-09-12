import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  CanLoad,
  Route,
  Router,
  RouterStateSnapshot,
  UrlSegment,
  UrlTree
} from '@angular/router';
import { AdminRole } from '../auth/admin-role.model';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate, CanActivateChild, CanLoad {
  constructor(
    private readonly authService: AuthService,
    private readonly router: Router
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean | UrlTree {
    return this.checkAccess(state.url, route.data?.['allowedRoles'] as AdminRole[] | undefined);
  }

  canActivateChild(childRoute: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean | UrlTree {
    return this.checkAccess(state.url, childRoute.data?.['allowedRoles'] as AdminRole[] | undefined);
  }

  canLoad(route: Route, segments: UrlSegment[]): boolean | UrlTree {
    const url = `/${segments.map((segment) => segment.path).join('/')}`;
    return this.checkAccess(url, route.data?.['allowedRoles'] as AdminRole[] | undefined);
  }

  private checkAccess(attemptedUrl: string, allowedRoles?: AdminRole[]): boolean | UrlTree {
    if (!this.authService.isLoggedIn()) {
      return this.router.createUrlTree(['/login']);
    }

    if (allowedRoles?.length && !this.authService.hasAnyRole(allowedRoles)) {
      return this.router.createUrlTree(['/access-denied'], {
        queryParams: {
          from: attemptedUrl || '/dashboard'
        }
      });
    }

    return true;
  }
}
