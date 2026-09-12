export interface ReturnRequest {
  id: number;
  orderId: number;
  customerId: number;
  productId?: number | null;
  orderReference?: string;
  customerName?: string;
  reason: string;
  note: string;
  status: string;
  requestedAt: string;
  updatedAt: string;
}
