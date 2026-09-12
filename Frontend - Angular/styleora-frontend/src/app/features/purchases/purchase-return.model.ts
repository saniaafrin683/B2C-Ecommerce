export interface PurchaseReturnLineItem {
  product: string;
  sku: string;
  quantity: number;
  unitCost: number;
  discount: number;
  tax: number;
  total: number;
}

export interface PurchaseReturn {
  id: number;
  returnId: string;
  purchaseOrderId: string;
  supplierName: string;
  supplierEmail?: string;
  supplierPhone?: string;
  returnDate: string;
  returnReason?: string;
  returnStatus: string;
  refundStatus: string;
  paymentMethod?: string;
  items: PurchaseReturnLineItem[];
  subtotal: number;
  tax: number;
  discount: number;
  totalAmount: number;
  notes?: string;
}
