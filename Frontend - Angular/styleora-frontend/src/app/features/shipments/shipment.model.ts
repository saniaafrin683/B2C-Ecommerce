export interface Shipment {

  id?: number;

  orderId?: number;

  orderNumber?: string;

  shippingMethodId?: number;

  trackingNumber?: string;

  courierName?: string;

  shipmentStatus?: string;

  status?: string;

  shippedDate?: string;

  dispatchDate?: string;

  estimatedDeliveryDate?: string;

  deliveredDate?: string;

  remarks?: string;
}