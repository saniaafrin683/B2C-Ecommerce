export interface Coupon {
  id: number;
  couponCode: string;
  discountType: string;
  discountValue: number;
  startDate: string;
  endDate: string;
  usageLimit: number;
  usedCount: number;
  minimumOrderAmount: number;
  status: string;
  description: string;
  createdAt: string;
  updatedAt: string;
}
