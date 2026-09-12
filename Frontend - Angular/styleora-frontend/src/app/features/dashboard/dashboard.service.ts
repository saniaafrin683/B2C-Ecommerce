import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  MonthlyOrdersReport,
  MonthlyRevenueReport,
  ReportSummary,
  TopCustomerReport,
  TopProductReport
} from '../reports/report.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  private readonly baseUrl = `${environment.apiBaseUrl}/reports`;

  constructor(private http: HttpClient) {}

  getSummary(range?: string): Observable<ReportSummary> {
    return this.http.get<ReportSummary>(`${this.baseUrl}/summary`, {
      params: this.buildRangeParams(range)
    });
  }

  getMonthlyRevenue(range?: string): Observable<MonthlyRevenueReport[]> {
    return this.http.get<MonthlyRevenueReport[]>(`${this.baseUrl}/revenue/monthly`, {
      params: this.buildRangeParams(range)
    });
  }

  getMonthlyOrders(range?: string): Observable<MonthlyOrdersReport[]> {
    return this.http.get<MonthlyOrdersReport[]>(`${this.baseUrl}/orders/monthly`, {
      params: this.buildRangeParams(range)
    });
  }

  getTopProducts(range?: string): Observable<TopProductReport[]> {
    return this.http.get<TopProductReport[]>(`${this.baseUrl}/top-products`, {
      params: this.buildRangeParams(range)
    });
  }

  getTopCustomers(range?: string): Observable<TopCustomerReport[]> {
    return this.http.get<TopCustomerReport[]>(`${this.baseUrl}/top-customers`, {
      params: this.buildRangeParams(range)
    });
  }

  exportCsv(range?: string): Observable<Blob> {
    return this.http.get(`${this.baseUrl}/export/csv`, {
      params: this.buildRangeParams(range),
      responseType: 'blob'
    });
  }

  private buildRangeParams(range?: string): HttpParams {
    let params = new HttpParams();
    if (range) {
      params = params.set('range', range);
    }
    return params;
  }
}
