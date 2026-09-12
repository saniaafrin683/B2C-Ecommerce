import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ReceivedOrderService } from '../received-orders/received-order.service';
import { ReceivedOrder } from '../received-orders/received-order.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-received-order-details',
  templateUrl: './received-order-details.component.html',
  styleUrls: ['./received-order-details.component.css']
})
export class ReceivedOrderDetailsComponent implements OnInit {

  order!: ReceivedOrder;
  loading = false;
  orderId: number = 0;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private receivedOrderService: ReceivedOrderService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.orderId = +id;
        this.loadOrder(this.orderId);
      } else {
        this.router.navigate(['/inventory/received-orders']);
      }
    });
  }

  loadOrder(id: number): void {
    this.loading = true;
    this.loadingService.show();

    this.receivedOrderService.getReceivedOrderById(id).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: ReceivedOrder) => {
        this.order = res;
      },
      error: (err) => {
        console.error('Failed to load received order details', err);
        this.notificationService.showError('Failed to load received order details.');
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/inventory/received-orders']);
  }

  goToEdit(): void {
    this.router.navigate(['/inventory/edit-received-order', this.orderId]);
  }
}
