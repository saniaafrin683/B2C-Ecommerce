import { Component } from '@angular/core';
import { Location } from '@angular/common';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-access-denied',
  templateUrl: './access-denied.component.html',
  styleUrls: ['./access-denied.component.css']
})
export class AccessDeniedComponent {
  constructor(
    private readonly authService: AuthService,
    private readonly location: Location
  ) {}

  goToDashboard(): void {
    if (window.history.length > 1) {
      this.location.back();
      return;
    }

    this.authService.navigateToDefaultDashboard();
  }
}
