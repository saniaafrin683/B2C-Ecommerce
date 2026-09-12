import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { SubCategory } from '../models/sub-category.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SubCategoryService {
  private readonly baseUrl = `${environment.apiBaseUrl}/sub-categories`;

  constructor(private readonly http: HttpClient) {}

  getSubCategories(): Observable<SubCategory[]> {
    return this.http.get<SubCategory[]>(`${this.baseUrl}/list`);
  }

  getSubCategoriesByCategoryId(categoryId: number): Observable<SubCategory[]> {
    return this.http.get<SubCategory[]>(`${this.baseUrl}/by-category/${categoryId}`).pipe(
      catchError(() => this.getSubCategories().pipe(
        map((subCategories) => (subCategories || []).filter((item) => item.categoryId === categoryId))
      ))
    );
  }
}
