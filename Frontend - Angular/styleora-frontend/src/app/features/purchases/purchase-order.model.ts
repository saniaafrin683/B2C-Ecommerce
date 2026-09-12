export interface PurchaseOrderLineItem {
  product: string;
  sku: string;
  quantity: number;
  unitCost: number;
  discount: number;
  tax: number;
  total: number;
}

export interface PurchaseOrder {
  id: number;
  purchaseOrderId: string;
  supplierName: string;
  supplierEmail?: string;
  supplierPhone?: string;
  supplierAddress?: string;
  orderDate: string;
  expectedDeliveryDate?: string;
  orderStatus: string;
  paymentStatus: string;
  paymentMethod?: string;
  items: PurchaseOrderLineItem[];
  subtotal: number;
  discount: number;
  tax: number;
  shippingCost: number;
  totalAmount: number;
  paidAmount: number;
  dueAmount: number;
  notes?: string;
}
