import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Category } from './category.model';
import { environment } from '../../../environments/environment';

export const CATEGORY_CACHE_KEY = 'styleora_category_cache';

@Injectable({
  providedIn: 'root'
})
export class CategoryService {
  private readonly baseUrl = `${environment.apiBaseUrl}/categories`;

  constructor(private http: HttpClient) {}

  createCategory(category: Category): Observable<Category> {
    return this.http.post<Category>(`${this.baseUrl}/create`, category).pipe(
      tap((createdCategory) => this.upsertCachedCategory(createdCategory))
    );
  }

  getAllCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(`${this.baseUrl}/list`).pipe(
      tap((categories) => this.cacheCategories(categories || []))
    );
  }

  getCategoryById(id: number): Observable<Category> {
    return this.http.get<Category>(`${this.baseUrl}/${id}`).pipe(
      tap((category) => this.upsertCachedCategory(category))
    );
  }

  updateCategory(id: number, category: Category): Observable<Category> {
    return this.http.put<Category>(`${this.baseUrl}/update/${id}`, category).pipe(
      tap((updatedCategory) => this.upsertCachedCategory(updatedCategory))
    );
  }

  deleteCategory(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/delete/${id}`, {
      responseType: 'text'
    }).pipe(
      tap(() => this.removeCachedCategory(id))
    );
  }

  getCachedCategories(): Category[] {
    if (!this.isBrowser()) {
      return [];
    }

    const rawValue = localStorage.getItem(CATEGORY_CACHE_KEY);
    if (!rawValue) {
      return [];
    }

    try {
      const parsed = JSON.parse(rawValue);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  cacheCategories(categories: Category[]): void {
    if (!this.isBrowser()) {
      return;
    }

    localStorage.setItem(CATEGORY_CACHE_KEY, JSON.stringify(categories || []));
  }

  private upsertCachedCategory(category: Category | null | undefined): void {
    if (!category || category.id == null) {
      return;
    }

    const categories = this.getCachedCategories();
    const index = categories.findIndex((item) => item.id === category.id);

    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.unshift(category);
    }

    this.cacheCategories(categories);
  }

  private removeCachedCategory(id: number): void {
    const categories = this.getCachedCategories().filter((item) => item.id !== id);
    this.cacheCategories(categories);
  }

  private isBrowser(): boolean {
    return typeof window !== 'undefined' && typeof localStorage !== 'undefined';
  }
}
