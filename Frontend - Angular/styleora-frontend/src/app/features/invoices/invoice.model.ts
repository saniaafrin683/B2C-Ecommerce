export interface Invoice {
  id: number;
  invoiceNumber: string;
  orderId: number;
  orderReference?: string;
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  billingAddress: string;
  subtotal: number;
  regularSubtotal?: number;
  productDiscountTotal?: number;
  subtotalAfterProductDiscount?: number;
  tax: number;
  discount: number;
  couponDiscount?: number;
  couponCode?: string;
  shippingCost: number;
  totalAmount: number;
  paymentStatus: string;
  paymentMethod: string;
  issueDate: string;
  dueDate: string;
  notes: string;
}
