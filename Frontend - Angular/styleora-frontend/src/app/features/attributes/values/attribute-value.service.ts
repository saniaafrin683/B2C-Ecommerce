import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { AttributeValue } from './attribute-value.model';
import { Attribute } from '../attribute.model';

interface AttributeValueApiModel {
  id?: number;
  attributeId?: number;
  value?: string;
  status?: string;
  createdAt?: string;
  updatedAt?: string;
  attribute?: Attribute | null;
}

@Injectable({
  providedIn: 'root'
})
export class AttributeValueService {
  private readonly baseUrl = 'http://localhost:8080/attribute-values';

  constructor(private http: HttpClient) {}

  getAttributeValues(): Observable<AttributeValue[]> {
    return this.http
      .get<AttributeValueApiModel[]>(`${this.baseUrl}/list`)
      .pipe(map((values) => (values || []).map((value) => this.toFrontend(value))));
  }

  getAttributeValueById(id: number): Observable<AttributeValue> {
    return this.http
      .get<AttributeValueApiModel>(`${this.baseUrl}/${id}`)
      .pipe(map((value) => this.toFrontend(value)));
  }

  getAttributeValuesByAttributeId(attributeId: number): Observable<AttributeValue[]> {
    return this.http
      .get<AttributeValueApiModel[]>(`${this.baseUrl}/by-attribute/${attributeId}`)
      .pipe(map((values) => (values || []).map((value) => this.toFrontend(value))));
  }

  createAttributeValue(attributeValue: AttributeValue): Observable<AttributeValue> {
    return this.http
      .post<AttributeValueApiModel>(`${this.baseUrl}/create`, this.toBackend(attributeValue))
      .pipe(map((value) => this.toFrontend(value)));
  }

  updateAttributeValue(id: number, attributeValue: AttributeValue): Observable<AttributeValue> {
    return this.http
      .put<AttributeValueApiModel>(`${this.baseUrl}/update/${id}`, this.toBackend(attributeValue))
      .pipe(map((value) => this.toFrontend(value)));
  }

  deleteAttributeValue(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }

  private toFrontend(attributeValue: AttributeValueApiModel): AttributeValue {
    const attribute = attributeValue.attribute || null;

    return {
      id: Number(attributeValue.id ?? 0),
      attributeId: Number(attributeValue.attributeId ?? attribute?.id ?? 0),
      attributeName: attribute?.attributeName || '',
      value: attributeValue.value || '',
      status: attributeValue.status || 'Active',
      createdAt: attributeValue.createdAt || '',
      updatedAt: attributeValue.updatedAt || '',
      attribute
    };
  }

  private toBackend(attributeValue: AttributeValue): AttributeValueApiModel {
    return {
      id: attributeValue.id,
      attributeId: attributeValue.attributeId,
      value: attributeValue.value,
      status: attributeValue.status,
      createdAt: attributeValue.createdAt || '',
      updatedAt: attributeValue.updatedAt || '',
      attribute: attributeValue.attributeId ? { id: attributeValue.attributeId } as Attribute : null
    };
  }
}
