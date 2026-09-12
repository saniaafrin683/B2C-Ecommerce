import { Component } from '@angular/core';
import { Observable } from 'rxjs';

import { ToastService, ToastState } from '../../../core/services/toast.service';

@Component({
  selector: 'app-toast',
  templateUrl: './app-toast.component.html',
  styleUrls: ['./app-toast.component.css']
})
export class AppToastComponent {
  readonly toast$: Observable<ToastState | null>;

  constructor(private readonly toastService: ToastService) {
    this.toast$ = this.toastService.toast$;
  }
}
