export interface Product {
  id?: number;
  name: string;
  category: string;
  subCategoryId?: number | null;
  subCategory?: string;
  brand: string;
  size?: string;
  sizes?: string[];
  selectedSizes?: string[];
  weight: string;
  gender: string;
  description: string;
  tagNumber: string;
  stock: number;
  tag: string;
  price: number;
  discount: number;
  tax: number;
  rating?: number;
  imageUrl: string;
  createdAt?: string;
  updatedAt?: string;
}
