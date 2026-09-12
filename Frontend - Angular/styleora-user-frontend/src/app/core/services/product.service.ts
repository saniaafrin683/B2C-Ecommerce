import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { map, Observable } from 'rxjs';

import { Product, ProductAttribute } from '../models/product.model';
import { environment } from '../../../environments/environment';

export interface ProductPageResponse {
  content: Product[];
  totalElements: number;
  totalPages: number;
  page: number;
  size: number;
  sortBy: string;
  sortDir: string;
}

export interface ProductSearchParams {
  query?: string;
  category?: string;
  brand?: string;
  gender?: string;
  tag?: string;
  minPrice?: number | null;
  maxPrice?: number | null;
  page?: number;
  size?: number;
  sortBy?: string;
  sortDir?: string;
}

export interface ProductStockAdjustmentResponse {
  productId: number;
  quantity: number;
  stock: number;
  message: string;
}

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private readonly backendOrigin = environment.apiBaseUrl || 'http://localhost:8080';
  private readonly apiBaseUrl = `${this.backendOrigin}/products`;
  private readonly productsUrl = `${this.backendOrigin}/products/list`;

  constructor(private readonly http: HttpClient) {}

  getProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(this.productsUrl).pipe(
      map((products) => (products || []).map((product) => this.normalizeProduct(product)))
    );
  }

  getProductsBySubCategory(subCategoryId: number): Observable<Product[]> {
    return this.http.get<Product[]>(`${this.apiBaseUrl}/by-subcategory/${subCategoryId}`).pipe(
      map((products) => (products || []).map((product) => this.normalizeProduct(product)))
    );
  }

  getProductsPage(page = 0, size = 12, sortBy = 'id', sortDir = 'desc'): Observable<ProductPageResponse> {
    const params = new HttpParams()
      .set('page', page)
      .set('size', size)
      .set('sortBy', sortBy)
      .set('sortDir', sortDir);

    return this.http.get<ProductPageResponse>(`${this.apiBaseUrl}/page`, { params }).pipe(
      map((response) => ({
        ...response,
        content: (response?.content || []).map((product) => this.normalizeProduct(product))
      }))
    );
  }

  searchProducts(searchParams: ProductSearchParams): Observable<ProductPageResponse> {
    let params = new HttpParams()
      .set('page', searchParams.page ?? 0)
      .set('size', searchParams.size ?? 12)
      .set('sortBy', searchParams.sortBy ?? 'id')
      .set('sortDir', searchParams.sortDir ?? 'desc');

    if (searchParams.query?.trim()) {
      params = params.set('query', searchParams.query.trim());
    }
    if (searchParams.category?.trim()) {
      params = params.set('category', searchParams.category.trim());
    }
    if (searchParams.brand?.trim()) {
      params = params.set('brand', searchParams.brand.trim());
    }
    if (searchParams.gender?.trim()) {
      params = params.set('gender', searchParams.gender.trim());
    }
    if (searchParams.tag?.trim()) {
      params = params.set('tag', searchParams.tag.trim());
    }
    if (searchParams.minPrice != null) {
      params = params.set('minPrice', searchParams.minPrice);
    }
    if (searchParams.maxPrice != null) {
      params = params.set('maxPrice', searchParams.maxPrice);
    }

    return this.http.get<ProductPageResponse>(`${this.apiBaseUrl}/search`, { params }).pipe(
      map((response) => ({
        ...response,
        content: (response?.content || []).map((product) => this.normalizeProduct(product))
      }))
    );
  }

  getProductById(id: number): Observable<Product> {
    return this.http.get<Product>(`${this.apiBaseUrl}/${id}`).pipe(
      map((product) => this.normalizeProduct(product))
    );
  }

  reserveStock(productId: number, quantity: number): Observable<ProductStockAdjustmentResponse> {
    return this.http.post<ProductStockAdjustmentResponse>(`${this.apiBaseUrl}/${productId}/reserve-stock`, { quantity });
  }

  releaseStock(productId: number, quantity: number): Observable<ProductStockAdjustmentResponse> {
    return this.http.post<ProductStockAdjustmentResponse>(`${this.apiBaseUrl}/${productId}/release-stock`, { quantity });
  }

  private normalizeProduct(product: Product): Product {
    const attributes = this.normalizeAttributes(product as Product & Record<string, unknown>);
    return {
      ...product,
      attributes,
      imageUrl: this.normalizeImageUrl(product?.imageUrl)
    };
  }

  private normalizeAttributes(product: (Product & Record<string, unknown>) | null | undefined): ProductAttribute[] {
    const normalizedAttributes: ProductAttribute[] = [];
    const seenKeys = new Set<string>();

    const pushAttribute = (key: string | null | undefined, value: unknown): void => {
      const normalizedKey = (key || '').trim();
      const normalizedValue = typeof value === 'string' ? value.trim() : String(value ?? '').trim();
      const dedupeKey = normalizedKey.toLowerCase();

      if (!normalizedKey || !normalizedValue || seenKeys.has(dedupeKey)) {
        return;
      }

      normalizedAttributes.push({ key: normalizedKey, value: normalizedValue });
      seenKeys.add(dedupeKey);
    };

    const attributeList = Array.isArray(product?.attributes) ? product?.attributes ?? [] : [];
    attributeList.forEach((attribute) => pushAttribute(attribute?.key, attribute?.value));

    const legacyAttributeMap: Array<[string, unknown]> = [
      ['Size', product?.size],
      ['Color', product?.color],
      ['Material', product?.material],
      ['Fabric', product?.fabric],
      ['Length', product?.length],
      ['Weight', product?.weight],
      ['Wash Care', product?.washCare]
    ];

    legacyAttributeMap.forEach(([key, value]) => pushAttribute(key, value));

    return normalizedAttributes;
  }

  private normalizeImageUrl(imageUrl: string | null | undefined): string {
    const value = (imageUrl || '').trim();

    if (!value) {
      return '';
    }

    if (value.startsWith('http://') || value.startsWith('https://') || value.startsWith('data:')) {
      return value;
    }

    if (value.startsWith('/')) {
      return `${this.backendOrigin}${value}`;
    }

    return `${this.backendOrigin}/${value.replace(/^\/+/, '')}`;
  }
}
