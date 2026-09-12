export interface Payment {
  id: number;
  invoiceId: number;
  orderId: number;
  customerName: string;
  amount: number;
  paymentMethod: string;
  transactionId: string;
  paymentStatus: string;
  paymentDate: string;
  notes: string;
  createdAt: string;
  updatedAt: string;
}
