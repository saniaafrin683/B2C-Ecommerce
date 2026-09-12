export interface CartItem {
  productId: number;
  name: string;
  price: number;
  discount?: number;
  imageUrl: string;
  size?: string;
  quantity: number;
  stock: number;
  reservedQuantity?: number;
  outOfStock?: boolean;
}
