import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export type NotificationType = 'success' | 'error' | 'warning' | 'info';

export interface NotificationToast {
  id: number;
  type: NotificationType;
  message: string;
}

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private readonly dismissDelayMs = 4000;
  private readonly toastsSubject = new BehaviorSubject<NotificationToast[]>([]);
  private nextId = 1;

  get toasts$(): Observable<NotificationToast[]> {
    return this.toastsSubject.asObservable();
  }

  showSuccess(message: string): void {
    this.show('success', message);
  }

  showError(message: string): void {
    this.show('error', message);
  }

  showWarning(message: string): void {
    this.show('warning', message);
  }

  showInfo(message: string): void {
    this.show('info', message);
  }

  dismiss(id: number): void {
    const toasts = this.toastsSubject.getValue().filter((toast) => toast.id !== id);
    this.toastsSubject.next(toasts);
  }

  private show(type: NotificationType, message: string): void {
    const toast: NotificationToast = {
      id: this.nextId++,
      type,
      message
    };

    this.toastsSubject.next([...this.toastsSubject.getValue(), toast]);

    window.setTimeout(() => {
      this.dismiss(toast.id);
    }, this.dismissDelayMs);
  }
}
