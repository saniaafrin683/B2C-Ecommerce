import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface ToastState {
  message: string;
  tone: 'success' | 'error' | 'info';
}

@Injectable({
  providedIn: 'root'
})
export class ToastService {
  private readonly toastSubject = new BehaviorSubject<ToastState | null>(null);
  private hideTimeoutId: ReturnType<typeof setTimeout> | null = null;

  readonly toast$ = this.toastSubject.asObservable();

  show(message: string, tone: 'success' | 'error' | 'info' = 'success', durationMs = 2400): void {
    this.toastSubject.next({ message, tone });

    if (this.hideTimeoutId) {
      clearTimeout(this.hideTimeoutId);
    }

    this.hideTimeoutId = setTimeout(() => {
      this.toastSubject.next(null);
      this.hideTimeoutId = null;
    }, durationMs);
  }
}
