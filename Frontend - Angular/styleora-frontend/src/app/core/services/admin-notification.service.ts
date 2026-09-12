import { Injectable, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable, Subscription, catchError, map, of, timer } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

export interface AdminNotificationItem {
  id: string;
  type: string;
  title: string;
  message: string;
  route: string;
  createdAt: string | null;
}

interface AdminNotificationResponse {
  notifications: AdminNotificationItem[];
}

@Injectable({
  providedIn: 'root'
})
export class AdminNotificationService implements OnDestroy {
  private readonly baseUrl = `${environment.apiBaseUrl}/notifications/admin`;
  private readonly storageKeyPrefix = 'styleora_admin_notification_reads';
  private readonly pollIntervalMs = 45000;
  private readonly notificationsSubject = new BehaviorSubject<AdminNotificationItem[]>([]);
  private readonly unreadCountSubject = new BehaviorSubject<number>(0);
  private pollingSubscription: Subscription | null = null;

  get notifications$(): Observable<AdminNotificationItem[]> {
    return this.notificationsSubject.asObservable();
  }

  get unreadCount$(): Observable<number> {
    return this.unreadCountSubject.asObservable();
  }

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
    private readonly router: Router
  ) {}

  startPolling(): void {
    if (this.pollingSubscription) {
      return;
    }

    this.pollingSubscription = timer(0, this.pollIntervalMs).subscribe(() => {
      this.refresh().subscribe();
    });
  }

  stopPolling(): void {
    this.pollingSubscription?.unsubscribe();
    this.pollingSubscription = null;
  }

  refresh(): Observable<AdminNotificationItem[]> {
    return this.http.get<AdminNotificationResponse>(this.baseUrl).pipe(
      map((response) => {
        const notifications = Array.isArray(response?.notifications) ? response.notifications : [];
        this.notificationsSubject.next(notifications);
        this.updateUnreadCount(notifications);
        return notifications;
      }),
      catchError(() => {
        this.notificationsSubject.next([]);
        this.unreadCountSubject.next(0);
        return of([]);
      })
    );
  }

  markAllAsRead(): void {
    const notifications = this.notificationsSubject.getValue();
    const readKeys = new Set(this.getStoredReadKeys());

    notifications.forEach((notification) => {
      readKeys.add(this.buildReadKey(notification));
    });

    this.storeReadKeys(Array.from(readKeys));
    this.updateUnreadCount(notifications);
  }

  markAsRead(notification: AdminNotificationItem): void {
    const readKeys = new Set(this.getStoredReadKeys());
    readKeys.add(this.buildReadKey(notification));
    this.storeReadKeys(Array.from(readKeys));
    this.updateUnreadCount(this.notificationsSubject.getValue());
  }

  isUnread(notification: AdminNotificationItem): boolean {
    return !this.getStoredReadKeys().includes(this.buildReadKey(notification));
  }

  navigate(notification: AdminNotificationItem): void {
    const route = (notification?.route || '').trim();
    if (!route) {
      return;
    }

    this.markAsRead(notification);
    this.router.navigateByUrl(route);
  }

  ngOnDestroy(): void {
    this.stopPolling();
  }

  private updateUnreadCount(notifications: AdminNotificationItem[]): void {
    const readKeys = new Set(this.getStoredReadKeys());
    const unreadCount = notifications.filter((notification) => !readKeys.has(this.buildReadKey(notification))).length;
    this.unreadCountSubject.next(unreadCount);
  }

  private buildReadKey(notification: AdminNotificationItem): string {
    return `${notification.id || 'notification'}|${notification.createdAt || ''}`;
  }

  private getStorageKey(): string {
    const email = this.authService.getAdminEmail().trim().toLowerCase() || 'admin';
    return `${this.storageKeyPrefix}:${email}`;
  }

  private getStoredReadKeys(): string[] {
    const rawValue = localStorage.getItem(this.getStorageKey());
    if (!rawValue) {
      return [];
    }

    try {
      const parsedValue = JSON.parse(rawValue);
      return Array.isArray(parsedValue) ? parsedValue.filter((value): value is string => typeof value === 'string') : [];
    } catch {
      localStorage.removeItem(this.getStorageKey());
      return [];
    }
  }

  private storeReadKeys(readKeys: string[]): void {
    localStorage.setItem(this.getStorageKey(), JSON.stringify(readKeys));
  }
}
