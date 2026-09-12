import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { SubCategory } from './sub-category.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SubCategoryService {
  private readonly baseUrl = `${environment.apiBaseUrl}/sub-categories`;

  constructor(private http: HttpClient) {}

  createSubCategory(subCategory: SubCategory): Observable<SubCategory> {
    return this.http.post<SubCategory>(`${this.baseUrl}/create`, subCategory);
  }

  getAllSubCategories(): Observable<SubCategory[]> {
    return this.http.get<SubCategory[]>(`${this.baseUrl}/list`);
  }

  getSubCategoryById(id: number): Observable<SubCategory> {
    return this.http.get<SubCategory>(`${this.baseUrl}/${id}`);
  }

  getSubCategoriesByCategoryId(categoryId: number): Observable<SubCategory[]> {
    return this.http.get<SubCategory[]>(`${this.baseUrl}/by-category/${categoryId}`).pipe(
      catchError(() => this.getAllSubCategories().pipe(
        map((subCategories) => (subCategories || []).filter((item) => item.categoryId === categoryId))
      ))
    );
  }

  updateSubCategory(id: number, subCategory: SubCategory): Observable<SubCategory> {
    return this.http.put<SubCategory>(`${this.baseUrl}/update/${id}`, subCategory);
  }

  deleteSubCategory(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/delete/${id}`, {
      responseType: 'text'
    });
  }
}
