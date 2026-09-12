import { Component, OnInit } from '@angular/core';
import { forkJoin, of } from 'rxjs';
import { catchError, finalize } from 'rxjs/operators';
import {
  MonthlyOrdersReport,
  MonthlyRevenueReport,
  ReportSummary,
  TopCustomerReport,
  TopProductReport
} from '../report.model';
import { ReportService } from '../report.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-reports-dashboard',
  templateUrl: './reports-dashboard.component.html',
  styleUrls: ['./reports-dashboard.component.css']
})
export class ReportsDashboardComponent implements OnInit {
  loading = false;
  errorMessage = '';

  summary: ReportSummary = {
    totalOrders: 0,
    totalRevenue: 0,
    totalCustomers: 0,
    totalProducts: 0,
    totalPayments: 0,
    pendingOrders: 0,
    pendingPayments: 0,
    pendingReviews: 0,
    lowStockItems: 0
  };

  monthlyRevenue: MonthlyRevenueReport[] = [];
  monthlyOrders: MonthlyOrdersReport[] = [];
  topProducts: TopProductReport[] = [];
  topCustomers: TopCustomerReport[] = [];

  constructor(
    private reportService: ReportService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadDashboard();
  }

  loadDashboard(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    forkJoin({
      summary: this.reportService.getSummary().pipe(
        catchError(() => {
          return of(this.createEmptySummary());
        })
      ),
      monthlyRevenue: this.reportService.getMonthlyRevenue().pipe(
        catchError(() => {
          return of([]);
        })
      ),
      monthlyOrders: this.reportService.getMonthlyOrders().pipe(
        catchError(() => {
          return of([]);
        })
      ),
      topProducts: this.reportService.getTopProducts().pipe(
        catchError(() => {
          return of([]);
        })
      ),
      topCustomers: this.reportService.getTopCustomers().pipe(
        catchError(() => {
          return of([]);
        })
      )
    }).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (result) => {
        this.summary = result.summary || this.summary;
        this.monthlyRevenue = result.monthlyRevenue || [];
        this.monthlyOrders = result.monthlyOrders || [];
        this.topProducts = result.topProducts || [];
        this.topCustomers = result.topCustomers || [];
      },
      error: () => {
        this.errorMessage = 'Failed to load analytics dashboard.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  private createEmptySummary(): ReportSummary {
    return {
      totalOrders: 0,
      totalRevenue: 0,
      totalCustomers: 0,
      totalProducts: 0,
      totalPayments: 0,
      pendingOrders: 0,
      pendingPayments: 0,
      pendingReviews: 0,
      lowStockItems: 0
    };
  }

  getRevenueBarHeight(item: MonthlyRevenueReport): number {
    const maxValue = Math.max(...this.monthlyRevenue.map(entry => Number(entry.revenue || 0)), 0);
    if (maxValue === 0) {
      return 18;
    }
    return Math.max(18, Math.round((Number(item.revenue || 0) / maxValue) * 100));
  }

  getOrdersBarHeight(item: MonthlyOrdersReport): number {
    const maxValue = Math.max(...this.monthlyOrders.map(entry => Number(entry.ordersCount || 0)), 0);
    if (maxValue === 0) {
      return 18;
    }
    return Math.max(18, Math.round((Number(item.ordersCount || 0) / maxValue) * 100));
  }
}
