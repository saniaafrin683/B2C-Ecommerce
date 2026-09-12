export interface CurrentStockSummary {
  productId: number;
  productName: string;
  category: string;
  currentStock: number;
  totalSold: number;
  totalPurchased: number;
  stockStatus: string;
}
