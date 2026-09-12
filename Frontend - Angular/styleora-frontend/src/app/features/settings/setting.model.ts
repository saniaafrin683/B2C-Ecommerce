export interface Setting {
  id: number;
  storeName: string;
  storeTagline: string;
  supportEmail: string;
  supportPhone: string;
  businessAddress: string;
  currency: string;
  taxRate: number;
  shippingCharge: number;
  orderPrefix: string;
  invoicePrefix: string;
  paymentMethods: string;
  logoUrl: string;
  faviconUrl: string;
  maintenanceMode: boolean;
  createdAt: string;
  updatedAt: string;
}
