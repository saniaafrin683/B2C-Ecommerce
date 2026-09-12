import { Component, EventEmitter, HostListener, OnDestroy, OnInit, Output } from '@angular/core';
import { Observable } from 'rxjs';
import { AuthService } from '../../core/services/auth.service';
import { NotificationService } from '../../shared/services/notification.service';
import { SettingsService } from '../../core/services/settings.service';
import { Setting } from '../../features/settings/setting.model';
import {
  AdminNotificationItem,
  AdminNotificationService
} from '../../core/services/admin-notification.service';

@Component({
  selector: 'app-topbar',
  templateUrl: './topbar.component.html',
  styleUrls: ['./topbar.component.css']
})
export class TopbarComponent implements OnInit, OnDestroy {
  @Output() menuToggle = new EventEmitter<void>();
  readonly settings$ = this.settingsService.settings$;
  readonly adminNotifications$: Observable<AdminNotificationItem[]> = this.adminNotificationService.notifications$;
  readonly unreadCount$: Observable<number> = this.adminNotificationService.unreadCount$;
  logoLoadFailed = false;
  notificationsOpen = false;

  constructor(
    private settingsService: SettingsService,
    private authService: AuthService,
    private notificationService: NotificationService,
    private adminNotificationService: AdminNotificationService
  ) {}

  ngOnInit(): void {
    this.adminNotificationService.refresh().subscribe();
  }

  ngOnDestroy(): void {
    this.adminNotificationService.stopPolling();
  }

  toggleSidebar(): void {
    this.menuToggle.emit();
  }

  toggleNotifications(event: Event): void {
    event.stopPropagation();
    this.notificationsOpen = !this.notificationsOpen;
  }

  closeNotifications(): void {
    this.notificationsOpen = false;
  }

  markAllNotificationsAsRead(event: Event): void {
    event.stopPropagation();
    this.adminNotificationService.markAllAsRead();
  }

  openNotification(notification: AdminNotificationItem, event: Event): void {
    event.stopPropagation();
    this.notificationsOpen = false;
    this.adminNotificationService.navigate(notification);
  }

  isUnread(notification: AdminNotificationItem): boolean {
    return this.adminNotificationService.isUnread(notification);
  }

  getNotificationBadgeLabel(count: number | null): string {
    const resolvedCount = count || 0;
    return resolvedCount > 9 ? '9+' : `${resolvedCount}`;
  }

  formatNotificationTime(createdAt: string | null): string {
    if (!createdAt) {
      return 'Just now';
    }

    const createdTime = new Date(createdAt).getTime();
    if (Number.isNaN(createdTime)) {
      return 'Recent';
    }

    const diffMs = Date.now() - createdTime;
    const diffMinutes = Math.max(1, Math.floor(diffMs / 60000));

    if (diffMinutes < 60) {
      return `${diffMinutes}m ago`;
    }

    const diffHours = Math.floor(diffMinutes / 60);
    if (diffHours < 24) {
      return `${diffHours}h ago`;
    }

    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}d ago`;
  }

  @HostListener('document:click')
  handleDocumentClick(): void {
    this.closeNotifications();
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

  getAdminName(): string {
    return this.authService.getAdminEmail();
  }

  onLogout(): void {
    this.adminNotificationService.stopPolling();
    this.authService.logout();
    this.notificationService.showInfo('Logged out successfully.');
  }
}
