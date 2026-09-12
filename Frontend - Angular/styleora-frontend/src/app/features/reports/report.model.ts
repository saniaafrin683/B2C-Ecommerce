export interface ReportSummary {
  totalOrders: number;
  totalRevenue: number;
  totalCustomers: number;
  totalProducts: number;
  totalPayments: number;
  pendingOrders: number;
  pendingPayments: number;
  pendingReviews: number;
  lowStockItems: number;
}

export interface MonthlyRevenueReport {
  month: string;
  revenue: number;
}

export interface MonthlyOrdersReport {
  month: string;
  ordersCount: number;
}

export interface TopProductReport {
  productName: string;
  totalSold: number;
  totalRevenue: number;
}

export interface TopCustomerReport {
  customerName: string;
  totalOrders: number;
  totalSpend: number;
}
