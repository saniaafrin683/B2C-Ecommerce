import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { OrderDetails, OrderService } from '../../../core/services/order.service';

@Component({
  selector: 'app-order-success',
  templateUrl: './order-success.component.html',
  styleUrls: ['./order-success.component.css']
})
export class OrderSuccessComponent implements OnInit {

  orderId: string | null = null;
  orderDbId: number | null = null;
  resolvedOrderDbId: number | null = null;
  isResolvingOrder = false;
  orderDetails: OrderDetails | null = null;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly orderService: OrderService
  ) {}

  ngOnInit(): void {
    this.orderId = this.route.snapshot.queryParamMap.get('orderId');
    const numericOrderId = Number(this.route.snapshot.queryParamMap.get('orderDbId'));
    this.orderDbId = Number.isFinite(numericOrderId) && numericOrderId > 0 ? numericOrderId : null;
    this.resolvedOrderDbId = this.orderDbId;

    if (!this.resolvedOrderDbId && this.orderId) {
      this.resolveOrderIdFromReference(this.orderId);
    }
  }

  goToOrders(): void {
    this.router.navigate(['/my-orders'], { queryParams: { placed: 1 } });
  }

  viewOrderDetails(): void {
    if (!this.resolvedOrderDbId) {
      return;
    }

    this.router.navigate(['/my-orders', this.resolvedOrderDbId]);
  }

  get canViewOrderDetails(): boolean {
    return !!this.resolvedOrderDbId;
  }

  private resolveOrderIdFromReference(orderReference: string): void {
    this.isResolvingOrder = true;
    this.orderService.getOrderByReference(orderReference).subscribe({
      next: (order) => {
        this.orderDetails = order;
        this.resolvedOrderDbId = order.id;
        this.isResolvingOrder = false;
      },
      error: () => {
        this.isResolvingOrder = false;
      }
    });
  }
}
