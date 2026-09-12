export interface SubCategory {
  id?: number;
  subCategoryCode?: string;
  subCategoryName: string;
  categoryId: number | null;
  categoryName?: string;
  createdBy?: string;
  stock?: number;
  tagId?: string;
  description?: string;
  imageUrl?: string;
  status?: string;
}
