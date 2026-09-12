export interface Warehouse {
  id?: number;
  warehouseId: string;
  warehouseName: string;
  location: string;
  manager: string;
  contactNumber: string;
  stockAvailable: number;
  stockShipping: number;
  warehouseRevenue: number;
}