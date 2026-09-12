export interface ReceivedOrder {
  id?: number;
  orderNo: string;
  supplierName: string;
  warehouseId: number | null;
  warehouseName: string;
  productId: number | null;
  productName: string;
  quantity: number;
  receivedDate: string;
  status: string;
  totalAmount: number;
  createdAt?: string;
  updatedAt?: string;
  stockApplied?: boolean;
}
