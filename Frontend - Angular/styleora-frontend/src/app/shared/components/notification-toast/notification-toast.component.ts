import { Component } from '@angular/core';
import { Observable } from 'rxjs';
import { NotificationService, NotificationToast } from '../../services/notification.service';

@Component({
  selector: 'app-notification-toast',
  templateUrl: './notification-toast.component.html',
  styleUrls: ['./notification-toast.component.css']
})
export class NotificationToastComponent {
  readonly toasts$: Observable<NotificationToast[]>;

  constructor(private notificationService: NotificationService) {
    this.toasts$ = this.notificationService.toasts$;
  }

  dismiss(id: number): void {
    this.notificationService.dismiss(id);
  }

  getToastClass(type: NotificationToast['type']): string {
    return `toast-${type}`;
  }

  getToastIcon(type: NotificationToast['type']): string {
    if (type === 'success') {
      return 'bi-check-circle-fill';
    }

    if (type === 'error') {
      return 'bi-x-circle-fill';
    }

    if (type === 'warning') {
      return 'bi-exclamation-triangle-fill';
    }

    return 'bi-info-circle-fill';
  }

  getToastTitle(type: NotificationToast['type']): string {
    if (type === 'success') {
      return 'Success';
    }

    if (type === 'error') {
      return 'Error';
    }

    if (type === 'warning') {
      return 'Warning';
    }

    return 'Info';
  }
}
