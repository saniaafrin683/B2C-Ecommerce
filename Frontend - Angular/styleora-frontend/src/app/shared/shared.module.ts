import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AppCurrencyPipe } from './pipes/app-currency.pipe';
import { LoadingSpinnerComponent } from './components/loading-spinner/loading-spinner.component';
import { NotificationToastComponent } from './components/notification-toast/notification-toast.component';

@NgModule({
  declarations: [AppCurrencyPipe, NotificationToastComponent, LoadingSpinnerComponent],
  imports: [CommonModule],
  exports: [AppCurrencyPipe, NotificationToastComponent, LoadingSpinnerComponent]
})
export class SharedModule {}
