import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { Product } from './product.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ProductService {

  private readonly baseUrl = `${environment.apiBaseUrl}/products`;
  private readonly backendOrigin = environment.apiBaseUrl;

  constructor(private http: HttpClient) {}

  createProduct(product: Product): Observable<Product> {
    return this.http.post<Product>(this.baseUrl + '/create', product).pipe(
      map((createdProduct) => this.normalizeProduct(createdProduct))
    );
  }

  createProductWithUpload(formData: FormData): Observable<Product> {
    return this.http.post<Product>(this.baseUrl + '/create-upload', formData).pipe(
      map((createdProduct) => this.normalizeProduct(createdProduct))
    );
  }

  getAllProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(this.baseUrl + '/list').pipe(
      map((products) => (products || []).map((product) => this.normalizeProduct(product)))
    );
  }

  getLowStockProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(this.baseUrl + '/low-stock').pipe(
      map((products) => (products || []).map((product) => this.normalizeProduct(product)))
    );
  }

  getProductById(id: number): Observable<Product> {
    return this.http.get<Product>(this.baseUrl + '/' + id).pipe(
      map((product) => this.normalizeProduct(product))
    );
  }

  updateProduct(id: number, product: Product): Observable<Product> {
    console.log('[Styleora Admin][Product Service] PUT body', { id, product });
    return this.http.put<Product>(this.baseUrl + '/update/' + id, product).pipe(
      map((updatedProduct) => this.normalizeProduct(updatedProduct))
    );
  }

  updateProductWithUpload(id: number, formData: FormData): Observable<Product> {
    console.log('[Styleora Admin][Product Service] PUT multipart body', {
      id,
      price: formData.get('price'),
      discount: formData.get('discount'),
      tax: formData.get('tax'),
      stock: formData.get('stock')
    });
    return this.http.put<Product>(this.baseUrl + '/update-upload/' + id, formData).pipe(
      map((updatedProduct) => this.normalizeProduct(updatedProduct))
    );
  }

  deleteProduct(id: number): Observable<any> {
    return this.http.delete(this.baseUrl + '/delete/' + id, {
      responseType: 'text' as 'json'
    });
  }

  buildProductUploadFormData(product: Product, imageFile?: File | null): FormData {
    const formData = new FormData();

    this.appendFormDataValue(formData, 'name', product.name);
    this.appendFormDataValue(formData, 'category', product.category);
    this.appendFormDataValue(formData, 'subCategoryId', product.subCategoryId);
    this.appendFormDataValue(formData, 'subCategory', product.subCategory);
    this.appendFormDataValue(formData, 'brand', product.brand);
    this.appendFormDataValue(formData, 'weight', product.weight);
    this.appendFormDataValue(formData, 'gender', product.gender);
    this.appendFormDataValue(formData, 'description', product.description);
    this.appendFormDataValue(formData, 'tagNumber', product.tagNumber);
    this.appendFormDataValue(formData, 'stock', product.stock);
    this.appendFormDataValue(formData, 'tag', product.tag);
    this.appendFormDataValue(formData, 'price', product.price);
    this.appendFormDataValue(formData, 'discount', product.discount);
    this.appendFormDataValue(formData, 'tax', product.tax);
    this.appendFormDataValue(formData, 'imageUrl', product.imageUrl);

    if (imageFile) {
      formData.append('imageFile', imageFile, imageFile.name);
    }

    return formData;
  }

  private normalizeProduct(product: Product): Product {
    return {
      ...product,
      subCategoryId: this.normalizeNullableId(product?.subCategoryId),
      subCategory: (product?.subCategory || '').trim(),
      stock: this.normalizeNumber(product?.stock, 0),
      price: this.normalizeNumber(product?.price, 0),
      discount: this.normalizeNumber(product?.discount, 0),
      tax: this.normalizeNumber(product?.tax, 0),
      imageUrl: this.normalizeImageUrl(product?.imageUrl)
    };
  }

  private normalizeNumber(value: number | string | null | undefined, fallback = 0): number {
    const normalizedValue = Number(value);
    return Number.isFinite(normalizedValue) ? normalizedValue : fallback;
  }

  private normalizeNullableId(value: number | string | null | undefined): number | null {
    if (value === null || value === undefined || value === '') {
      return null;
    }

    const normalizedValue = Number(value);
    return Number.isFinite(normalizedValue) ? normalizedValue : null;
  }

  private appendFormDataValue(formData: FormData, key: string, value: string | number | null | undefined): void {
    if (value === null || value === undefined) {
      return;
    }

    formData.append(key, String(value));
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
