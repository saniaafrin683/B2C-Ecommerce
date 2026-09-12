export interface OrderItem {
  id?: number;
  productId?: number;
  productName?: string;
  productImage?: string;
  size?: string;
  color?: string;
  originalUnitPrice?: number;
  discountedUnitPrice?: number;
  productDiscountRate?: number;
  productDiscountAmount?: number;
  originalLineTotal?: number;
  productDiscountLineTotal?: number;
  unitPrice?: number;
  quantity?: number;
  lineTotal?: number;
}

export interface Order {

  id?: number;

  orderId?: string;

  createdAt?: string;
  createdDate?: string;

  customerName?: string;
  customerEmail?: string;
  customerPhone?: string;

  email?: string;
  phone?: string;

  productName?: string;
  productImage?: string;

  quantity?: number;
  items?: number;

  regularSubtotal?: number;
  productDiscountTotal?: number;
  subtotalAfterProductDiscount?: number;
  subtotal?: number;
  tax?: number;
  discount?: number;
  couponDiscount?: number;
  couponCode?: string;
  shippingCost?: number;

  totalAmount?: number;
  grandTotal?: number;
  amount?: number;

  paymentMethod?: string;
  paymentStatus?: string;

  orderStatus?: string;
  status?: string;

  priority?: string;

  deliveryNumber?: string;
  trackingNumber?: string;
  courierName?: string;
  shipmentStatus?: string;
  shippedDate?: string;
  estimatedDeliveryDate?: string;
  deliveredDate?: string;

  shippingAddress?: string;
  billingAddress?: string;

  orderItems?: OrderItem[];

  address?: string;
  customer_address?: string;

}
