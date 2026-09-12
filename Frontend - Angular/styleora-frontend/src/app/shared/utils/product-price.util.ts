import { Product } from '../../features/products/product.model';

export function getProductDisplayPrice(product: Pick<Product, 'price' | 'discount'> | null | undefined): number {
  const price = normalizeAmount(product?.price);
  const discount = normalizePercent(product?.discount);

  if (discount <= 0) {
    return price;
  }

  return Math.max(price - (price * discount) / 100, 0);
}

export function hasProductDiscount(product: Pick<Product, 'discount'> | null | undefined): boolean {
  return normalizePercent(product?.discount) > 0;
}

function normalizeAmount(value: number | string | null | undefined): number {
  const amount = Number(value ?? 0);
  return Number.isFinite(amount) ? Math.max(amount, 0) : 0;
}

function normalizePercent(value: number | string | null | undefined): number {
  const percent = Number(value ?? 0);
  return Number.isFinite(percent) ? Math.max(percent, 0) : 0;
}
