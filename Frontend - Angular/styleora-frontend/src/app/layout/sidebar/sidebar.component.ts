import { Component, Input, OnDestroy, OnInit } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { SettingsService } from '../../core/services/settings.service';
import { AuthService } from '../../core/services/auth.service';
import {
  AdminRole,
  ADMIN_ONLY_ROLES,
  CUSTOMER_VIEW_ROLES,
  DASHBOARD_ACCESS_ROLES,
  MODERATION_ACCESS_ROLES,
  ORDER_VIEW_ROLES,
  SALES_ACCESS_ROLES
} from '../../core/auth/admin-role.model';
import { Setting } from '../../features/settings/setting.model';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';
import { NotificationService } from '../../shared/services/notification.service';

interface SidebarSubItem {
  title: string;
  route: string;
  allowedRoles?: AdminRole[];
}

interface SidebarItem {
  title: string;
  icon: string;
  route?: string;
  allowedRoles?: AdminRole[];
  expanded?: boolean;
  children?: SidebarSubItem[];
}

interface SidebarSection {
  title: string;
  items: SidebarItem[];
}

@Component({
  selector: 'app-sidebar',
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.css']
})
export class SidebarComponent implements OnInit, OnDestroy {
  @Input() collapsed = false;
  readonly settings$ = this.settingsService.settings$;
  logoLoadFailed = false;
  visiblePrimaryItems: SidebarItem[] = [];
  visibleMenuSections: SidebarSection[] = [];
  private readonly destroy$ = new Subject<void>();

  constructor(
    private settingsService: SettingsService,
    private authService: AuthService,
    private notificationService: NotificationService,
    private router: Router
  ) {}

  primaryItems: SidebarItem[] = [
    {
      title: 'Dashboard',
      icon: 'bi bi-grid',
      route: '/dashboard',
      allowedRoles: DASHBOARD_ACCESS_ROLES
    }
  ];

  menuSections: SidebarSection[] = [
    {
      title: 'Catalog',
      items: [
        {
          title: 'Catalog',
          icon: 'bi bi-box-seam',
          allowedRoles: ADMIN_ONLY_ROLES,
          expanded: false,
          children: [
            { title: 'Products', route: '/products/list' },
            { title: 'Create Product', route: '/products/create' },
            { title: 'Product Grid', route: '/products/grid' },
            { title: 'Categories', route: '/category/list' },
            { title: 'Sub Categories', route: '/sub-category/list' }
          ]
        }
      ]
    },
    {
      title: 'Inventory',
      items: [
        {
          title: 'Inventory',
          icon: 'bi bi-building',
          allowedRoles: ADMIN_ONLY_ROLES,
          expanded: false,
          children: [
            { title: 'Current Stock', route: '/inventory/current-stock' },
            { title: 'Purchases', route: '/purchases/list' },
            { title: 'Warehouse', route: '/inventory/warehouse' }
          ]
        }
      ]
    },
    {
      title: 'Shipping',
      items: [
        {
          title: 'Shipping Methods',
          icon: 'bi bi-truck',
          route: '/shipping-methods/list',
          allowedRoles: ADMIN_ONLY_ROLES
        }
      ]
    },
    {
      title: 'Orders',
      items: [
        {
          title: 'Orders',
          icon: 'bi bi-bag-check',
          expanded: false,
          children: [
            { title: 'Order List', route: '/orders/list', allowedRoles: ORDER_VIEW_ROLES },
            { title: 'Shipments', route: '/shipments/list', allowedRoles: SALES_ACCESS_ROLES },
            { title: 'Returns', route: '/returns/list', allowedRoles: MODERATION_ACCESS_ROLES }
          ]
        }
      ]
    },
    {
      title: 'Sales',
      items: [
        {
          title: 'Customers',
          icon: 'bi bi-people',
          expanded: false,
          children: [
            { title: 'All Customers', route: '/customers/list', allowedRoles: CUSTOMER_VIEW_ROLES },
            { title: 'Add Customers', route: '/customers/create', allowedRoles: ADMIN_ONLY_ROLES },
            { title: 'Restore Customers', route: '/customers/restore', allowedRoles: ADMIN_ONLY_ROLES }
          ]
        },
        {
          title: 'Coupons',
          icon: 'bi bi-ticket-perforated',
          route: '/coupons/list',
          allowedRoles: ADMIN_ONLY_ROLES
        },
        {
          title: 'Reviews',
          icon: 'bi bi-star',
          route: '/reviews/list',
          allowedRoles: MODERATION_ACCESS_ROLES
        }
      ]
    },
    {
      title: 'Finance',
      items: [
        {
          title: 'Invoices',
          icon: 'bi bi-receipt',
          expanded: false,
          children: [
            { title: 'List', route: '/invoices/list', allowedRoles: SALES_ACCESS_ROLES }
          ]
        },
        {
          title: 'Payments',
          icon: 'bi bi-credit-card-2-front',
          expanded: false,
          children: [
            { title: 'List', route: '/payments/list', allowedRoles: SALES_ACCESS_ROLES },
            { title: 'Create', route: '/payments/create', allowedRoles: SALES_ACCESS_ROLES }
          ]
        }
      ]
    },
    {
      title: 'Analytics',
      items: [
        {
          title: 'Reports',
          icon: 'bi bi-bar-chart-line',
          expanded: false,
          children: [
            { title: 'Analytics Dashboard', route: '/reports/dashboard', allowedRoles: DASHBOARD_ACCESS_ROLES }
          ]
        }
      ]
    },
    {
      title: 'System',
      items: [
        {
          title: 'Users',
          icon: 'bi bi-person-gear',
          allowedRoles: ADMIN_ONLY_ROLES,
          expanded: false,
          children: [
            { title: 'Users List', route: '/users/list' },
            { title: 'Create User', route: '/users/create' }
          ]
        },
        {
          title: 'Roles',
          icon: 'bi bi-person-badge',
          route: '/roles/list',
          allowedRoles: ADMIN_ONLY_ROLES
        },
        {
          title: 'Settings',
          icon: 'bi bi-gear',
          route: '/settings/general',
          allowedRoles: ADMIN_ONLY_ROLES
        }
      ]
    }
  ];

  ngOnInit(): void {
    this.updateVisibleMenus();
    this.syncExpandedMenus(this.router.url);

    this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        takeUntil(this.destroy$)
      )
      .subscribe((event) => {
        this.syncExpandedMenus(event.urlAfterRedirects);
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  toggleMenu(item: SidebarItem): void {
    if (this.collapsed || !item.children) {
      return;
    }
    item.expanded = !item.expanded;
  }

  shouldShowLogoImage(settings: Setting): boolean {
    const logoUrl = (settings?.logoUrl || '').trim();
    return !!logoUrl && !this.logoLoadFailed;
  }

  onLogoError(event: Event): void {
    this.logoLoadFailed = true;
    const image = event.target as HTMLImageElement | null;
    if (image) {
      image.style.display = 'none';
    }
  }

  onLogoLoad(): void {
    this.logoLoadFailed = false;
  }

  trackLogoState(settings: Setting): string {
    const logoUrl = (settings?.logoUrl || '').trim();
    if (!logoUrl) {
      this.logoLoadFailed = false;
    }
    return logoUrl;
  }

  onLogout(): void {
    this.authService.logout();
    this.notificationService.showInfo('Logged out successfully.');
  }

  getVisibleChildren(item: SidebarItem): SidebarSubItem[] {
    if (!this.hasRoleAccess(item.allowedRoles)) {
      return [];
    }

    return (item.children || []).filter((child) => this.hasRoleAccess(child.allowedRoles));
  }

  private syncExpandedMenus(url: string): void {
    const normalizedUrl = (url || '').toLowerCase();
    const groups = [this.primaryItems, ...this.menuSections.map((section) => section.items)];

    groups.forEach((items) => {
      items.forEach((item) => {
        if (!item.children) {
          return;
        }

        const visibleChildren = this.getVisibleChildren(item);
        item.expanded = visibleChildren.some((child) =>
          normalizedUrl === child.route.toLowerCase() || normalizedUrl.startsWith(`${child.route.toLowerCase()}/`)
        );
      });
    });
  }

  private updateVisibleMenus(): void {
    this.visiblePrimaryItems = this.primaryItems.filter((item) => this.isItemVisible(item));
    this.visibleMenuSections = this.menuSections
      .map((section) => ({
        ...section,
        items: section.items.filter((item) => this.isItemVisible(item))
      }))
      .filter((section) => section.items.length > 0);
  }

  private isItemVisible(item: SidebarItem): boolean {
    if (item.children?.length) {
      return this.getVisibleChildren(item).length > 0;
    }

    return this.hasRoleAccess(item.allowedRoles);
  }

  private hasRoleAccess(allowedRoles?: AdminRole[]): boolean {
    return !allowedRoles?.length || this.authService.hasAnyRole(allowedRoles);
  }
}
