import { Component, OnDestroy, OnInit } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';

import { OrderSummary, OrderService } from '../../core/services/order.service';

@Component({
  selector: 'app-orders',
  templateUrl: './orders.component.html',
  styleUrls: ['./orders.component.css']
})
export class OrdersComponent implements OnInit, OnDestroy {
  orders: OrderSummary[] = [];
  isLoading = true;
  errorMessage = '';
  showPlacedModal = false;

  constructor(
    private readonly orderService: OrderService,
    private readonly route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    if (this.route.snapshot.queryParamMap.get('placed') === '1') {
      this.showPlacedModal = true;
    }

    this.orderService.getOrders().subscribe({
      next: (orders) => {
        this.orders = [...orders].sort((left, right) => right.id - left.id);
        this.isLoading = false;
      },
      error: (error: HttpErrorResponse) => {
        this.errorMessage = error.error?.message || 'Unable to load your orders right now.';
        this.isLoading = false;
      }
    });
  }

  ngOnDestroy(): void {
  }

  closePlacedModal(): void {
    this.showPlacedModal = false;
  }

  trackByOrderId(index: number, order: OrderSummary): number {
    return order.id;
  }
}
