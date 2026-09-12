export interface ProductAttribute {
  key: string;
  value: string;
}

export interface Product {
  id: number;
  name: string;
  price: number;
  discount: number;
  stock: number;
  imageUrl: string;
  category: string;
  subCategoryId?: number | null;
  subCategory?: string;
  subcategory?: string;
  gender?: string;
  brand?: string;
  description?: string;
  attributes?: ProductAttribute[];
  size?: string;
  color?: string;
  material?: string;
  fabric?: string;
  length?: string;
  weight?: string;
  washCare?: string;
}
