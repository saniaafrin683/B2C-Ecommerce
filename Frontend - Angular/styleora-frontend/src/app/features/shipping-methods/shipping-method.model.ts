export interface ShippingMethod {
  id: number;
  name: string;
  description: string;
  coverageArea: string;
  courierName: string;
  cost: number;
  minOrderAmount: number;
  maxWeightKg: number;
  isFreeShipping: boolean;
  estimatedDays: number;
  sortOrder: number;
  status: string;
}
