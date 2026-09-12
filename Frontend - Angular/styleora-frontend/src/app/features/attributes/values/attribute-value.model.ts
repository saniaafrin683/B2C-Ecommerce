import { Attribute } from '../attribute.model';

export interface AttributeValue {
  id: number;
  attributeId: number;
  attributeName: string;
  value: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  attribute?: Attribute | null;
}
