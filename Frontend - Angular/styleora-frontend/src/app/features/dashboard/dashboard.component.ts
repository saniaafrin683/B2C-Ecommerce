import { Component, OnInit } from '@angular/core';
import { forkJoin, of } from 'rxjs';
import { catchError, finalize } from 'rxjs/operators';
import { Order } from '../orders/order.model';
import { OrdersService } from '../orders/orders.service';
import { Product } from '../products/product.model';
import { ProductService } from '../products/product.service';
import { Review } from '../reviews/review.model';
import { ReviewService } from '../reviews/review.service';
import { ReturnRequest } from '../returns/return-request.model';
import { ReturnRequestService } from '../returns/return-request.service';
import { Shipment } from '../shipments/shipment.model';
import { ShipmentService } from '../shipments/shipment.service';
import {
  MonthlyOrdersReport,
  MonthlyRevenueReport,
  ReportSummary,
  TopCustomerReport,
  TopProductReport
} from '../reports/report.model';
import { LoadingService } from '../../shared/services/loading.service';
import { NotificationService } from '../../shared/services/notification.service';
import { DashboardService } from './dashboard.service';

interface DashboardStatCard {
  title: string;
  value: number | string;
  subtitle: string;
  icon: string;
  accentClass: string;
}

interface DashboardActivityItem {
  title: string;
  description: string;
  accentClass: string;
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  loading = false;
  exporting = false;
  errorMessage = '';
  warningMessage = '';

  readonly rangeOptions = [
    { label: 'Today', value: 'today' },
    { label: 'Last 7 days', value: '7d' },
    { label: 'Last 30 days', value: '30d' },
    { label: 'Last 12 months', value: '12m' }
  ];

  selectedRange = '30d';
  dashboardSubtitle = 'Track revenue momentum, recent orders, and what needs attention across your catalog.';
  recentOrdersTitle = 'Recent Orders';
  recentOrdersSubtitle = 'Latest checkout activity across the store.';
  activityPanelTitle = 'Pending Actions';
  activityPanelSubtitle = 'Key items that currently need admin attention.';
  showAnalyticsSection = true;
  showTopProductsSection = true;
  showTopCustomersSection = true;
  showLowStockSectionFlag = true;

  summary: ReportSummary = this.createEmptySummary();
  statCards: DashboardStatCard[] = [];
  actionItems: DashboardActivityItem[] = [];
  recentOrders: Order[] = [];
  monthlyRevenue: MonthlyRevenueReport[] = [];
  monthlyOrders: MonthlyOrdersReport[] = [];
  topProducts: TopProductReport[] = [];
  topCustomers: TopCustomerReport[] = [];
  lowStockProducts: Product[] = [];
  reviews: Review[] = [];
  returnRequests: ReturnRequest[] = [];
  shipments: Shipment[] = [];

  constructor(
    private dashboardService: DashboardService,
    private ordersService: OrdersService,
    private productService: ProductService,
    private reviewService: ReviewService,
    private returnRequestService: ReturnRequestService,
    private shipmentService: ShipmentService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.rebuildDashboardCards();
    this.loadDashboard();
  }

  loadDashboard(): void {
    this.loading = true;
    this.errorMessage = '';
    this.warningMessage = '';
    this.loadingService.show();

    const warnings = new Set<string>();

    forkJoin({
      summary: this.dashboardService.getSummary(this.selectedRange).pipe(
        catchError(() => {
          this.errorMessage = 'Dashboard summary could not be loaded. Showing fallback values.';
          return of(this.createEmptySummary());
        })
      ),
      monthlyRevenue: this.dashboardService.getMonthlyRevenue(this.getChartRange()).pipe(
        catchError(() => {
          warnings.add('Revenue trend data is unavailable right now.');
          return of([]);
        })
      ),
      monthlyOrders: this.dashboardService.getMonthlyOrders(this.getChartRange()).pipe(
        catchError(() => {
          warnings.add('Order trend data is unavailable right now.');
          return of([]);
        })
      ),
      topProducts: this.dashboardService.getTopProducts(this.selectedRange).pipe(
        catchError(() => {
          warnings.add('Top product data is unavailable right now.');
          return of([]);
        })
      ),
      topCustomers: this.dashboardService.getTopCustomers(this.selectedRange).pipe(
        catchError(() => {
          warnings.add('Top customer data is unavailable right now.');
          return of([]);
        })
      ),
      recentOrders: this.ordersService.getAllOrders().pipe(
        catchError(() => {
          warnings.add('Recent orders are unavailable right now.');
          return of([]);
        })
      ),
      lowStockProducts: this.productService.getLowStockProducts().pipe(
        catchError(() => {
          warnings.add('Low stock product data is unavailable right now.');
          return of([]);
        })
      ),
      reviews: this.reviewService.getReviews().pipe(
        catchError(() => {
          warnings.add('Review moderation data is unavailable right now.');
          return of([]);
        })
      ),
      returnRequests: this.returnRequestService.getReturnRequests().pipe(
        catchError(() => {
          warnings.add('Return request data is unavailable right now.');
          return of([]);
        })
      ),
      shipments: this.shipmentService.getShipments().pipe(
        catchError(() => {
          warnings.add('Shipment data is unavailable right now.');
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
        this.summary = result.summary || this.createEmptySummary();
        this.monthlyRevenue = result.monthlyRevenue || [];
        this.monthlyOrders = result.monthlyOrders || [];
        this.topProducts = result.topProducts || [];
        this.topCustomers = result.topCustomers || [];
        this.lowStockProducts = (result.lowStockProducts || []).slice(0, 5);
        this.reviews = result.reviews || [];
        this.returnRequests = result.returnRequests || [];
        this.shipments = result.shipments || [];
        this.recentOrders = ((result.recentOrders || []) as Order[])
          .slice()
          .sort((a, b) => this.getOrderSortValue(b) - this.getOrderSortValue(a))
          .slice(0, 5);
        this.rebuildDashboardCards();

        if (warnings.size > 0) {
          this.warningMessage = Array.from(warnings).join(' ');
          this.notificationService.showWarning('Some dashboard sections could not be loaded. Fallback values are being shown.');
        }

        if (this.errorMessage) {
          this.notificationService.showWarning(this.errorMessage);
        }
      },
      error: () => {
        this.summary = this.createEmptySummary();
        this.monthlyRevenue = [];
        this.monthlyOrders = [];
        this.topProducts = [];
        this.topCustomers = [];
        this.lowStockProducts = [];
        this.reviews = [];
        this.returnRequests = [];
        this.shipments = [];
        this.recentOrders = [];
        this.rebuildDashboardCards();
        this.errorMessage = 'Failed to load dashboard analytics. Please refresh and try again.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onRangeChange(): void {
    this.loadDashboard();
  }

  onExport(): void {
    this.exporting = true;
    this.loadingService.show();
    this.dashboardService.exportCsv(this.selectedRange).pipe(
      finalize(() => {
        this.exporting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'styleora-dashboard-report.csv';
        link.click();
        window.URL.revokeObjectURL(url);
      },
      error: () => {
        this.errorMessage = 'Failed to export dashboard report.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  getRevenueBarHeight(item: MonthlyRevenueReport): number {
    const maxValue = Math.max(...this.monthlyRevenue.map((entry) => Number(entry.revenue || 0)), 0);
    return maxValue === 0 ? 18 : Math.max(18, Math.round((Number(item.revenue || 0) / maxValue) * 100));
  }

  getOrdersBarHeight(item: MonthlyOrdersReport): number {
    const maxValue = Math.max(...this.monthlyOrders.map((entry) => Number(entry.ordersCount || 0)), 0);
    return maxValue === 0 ? 18 : Math.max(18, Math.round((Number(item.ordersCount || 0) / maxValue) * 100));
  }

  getStatusClass(status: string | undefined): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('complete') || normalized.includes('deliver')) {
      return 'pill-success';
    }
    if (normalized.includes('cancel') || normalized.includes('reject')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }

  getRangeLabel(): string {
    return this.rangeOptions.find((option) => option.value === this.selectedRange)?.label || 'Last 30 days';
  }

  getActivityColor(accentClass: string): string {
    switch (accentClass) {
      case 'orders':
        return '#2563eb';
      case 'revenue':
        return '#16a34a';
      case 'customers':
        return '#f59e0b';
      case 'inventory':
        return '#ef4444';
      default:
        return '#94a3b8';
    }
  }

  private rebuildDashboardCards(): void {
    this.statCards = [
      {
        title: 'Total Revenue',
        value: this.formatCompactCurrency(this.summary.totalRevenue),
        subtitle: this.getRangeLabel(),
        icon: 'bi bi-cash-stack',
        accentClass: 'green'
      },
      {
        title: 'Total Orders',
        value: this.summary.totalOrders,
        subtitle: `${this.summary.pendingOrders} pending`,
        icon: 'bi bi-cart',
        accentClass: 'blue'
      },
      {
        title: 'Inventory',
        value: this.summary.totalProducts,
        subtitle: 'Products in active catalog',
        icon: 'bi bi-box-seam',
        accentClass: 'amber'
      },
      {
        title: 'Low Stock',
        value: this.summary.lowStockItems,
        subtitle: 'Items below threshold',
        icon: 'bi bi-exclamation-triangle',
        accentClass: 'rose'
      },
      {
        title: 'Pending Reviews',
        value: this.summary.pendingReviews,
        subtitle: 'Waiting for moderation',
        icon: 'bi bi-star',
        accentClass: 'violet'
      },
      {
        title: 'Pending Returns',
        value: this.getPendingReturnCount(),
        subtitle: 'Cases requiring review',
        icon: 'bi bi-arrow-counterclockwise',
        accentClass: 'orange'
      },
      {
        title: 'Pending Payments',
        value: this.summary.pendingPayments,
        subtitle: 'Transactions still open',
        icon: 'bi bi-credit-card',
        accentClass: 'green'
      },
      {
        title: 'Shipments',
        value: this.shipments.length,
        subtitle: `${this.getActiveShipmentCount()} active in transit`,
        icon: 'bi bi-truck',
        accentClass: 'blue'
      }
    ];

    this.actionItems = [
      {
        title: `${this.summary.pendingOrders} pending orders`,
        description: 'Orders still awaiting confirmation, processing, or dispatch.',
        accentClass: 'orders'
      },
      {
        title: `${this.summary.pendingPayments} pending payments`,
        description: 'Transactions that still require payment confirmation.',
        accentClass: 'revenue'
      },
      {
        title: `${this.summary.pendingReviews} pending reviews`,
        description: 'Review submissions waiting for moderation approval.',
        accentClass: 'customers'
      },
      {
        title: `${this.getPendingReturnCount()} pending returns`,
        description: 'Return cases that still need a resolution.',
        accentClass: 'orders'
      },
      {
        title: `${this.summary.lowStockItems} low stock items`,
        description: 'Products below the stock threshold should be restocked soon.',
        accentClass: 'inventory'
      },
      {
        title: `${this.getActiveShipmentCount()} active shipments`,
        description: 'Shipments currently moving through fulfillment.',
        accentClass: 'revenue'
      }
    ];
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

  private getChartRange(): string {
    return this.selectedRange === 'today' || this.selectedRange === '7d' || this.selectedRange === '30d'
      ? '12m'
      : this.selectedRange;
  }

  private getOrderSortValue(order: Order): number {
    const source = order.createdAt || order.createdDate || '';
    const parsed = Date.parse(source);
    return Number.isNaN(parsed) ? Number(order.id || 0) : parsed;
  }

  private getPendingReturnCount(): number {
    return this.returnRequests.filter((request) => this.isPendingState(request.status)).length;
  }

  private getActiveShipmentCount(): number {
    return this.shipments.filter((shipment) => {
      const normalized = (shipment.shipmentStatus || shipment.status || '').toLowerCase();
      return normalized && !normalized.includes('deliver');
    }).length;
  }

  private isPendingState(status: string | undefined): boolean {
    const normalized = (status || '').toLowerCase();
    return normalized.includes('pending') || normalized.includes('request') || normalized.includes('review');
  }

  private formatCompactCurrency(value: number): string {
    return new Intl.NumberFormat('en-US', {
      notation: 'compact',
      maximumFractionDigits: 1
    }).format(Number(value || 0));
  }
}
