export interface PurchaseLineItem {
  id?: number;
  productId: number | null;
  productName: string;
  category?: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
  availableStock?: number;
}

export interface Purchase {
  id: number;
  purchaseId: string;
  supplierName: string;
  supplierEmail?: string;
  supplierPhone?: string;
  supplierAddress?: string;
  items: PurchaseLineItem[];
  purchaseStatus: string;
  purchaseDate: string;
  totalAmount: number;
  paymentMethod: string;
  paymentStatus: string;
  paidAmount: number;
  dueAmount: number;
  subtotal: number;
  discount: number;
  tax: number;
  shippingCost: number;
  notes?: string;
  stockApplied: boolean;
}
