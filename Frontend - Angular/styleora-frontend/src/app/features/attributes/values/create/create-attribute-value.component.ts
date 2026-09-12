import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Attribute } from '../../attribute.model';
import { AttributeService } from '../../attribute.service';
import { AttributeValue } from '../attribute-value.model';
import { AttributeValueService } from '../attribute-value.service';

@Component({
  selector: 'app-create-attribute-value',
  templateUrl: './create-attribute-value.component.html',
  styleUrls: ['./create-attribute-value.component.css']
})
export class CreateAttributeValueComponent implements OnInit {
  attributes: Attribute[] = [];
  submitting = false;
  loadingAttributes = false;
  errorMessage = '';

  readonly statuses = ['Active', 'Inactive', 'Draft'];

  valueForm: AttributeValue = this.createInitialForm();

  constructor(
    private attributeService: AttributeService,
    private attributeValueService: AttributeValueService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadAttributes();
  }

  loadAttributes(): void {
    this.loadingAttributes = true;

    this.attributeService.getAttributes().subscribe({
      next: (attributes) => {
        this.attributes = attributes || [];
        this.loadingAttributes = false;
      },
      error: () => {
        this.loadingAttributes = false;
        this.errorMessage = 'Failed to load attributes.';
      }
    });
  }

  onSave(): void {
    this.errorMessage = '';

    if (!this.valueForm.attributeId || !this.valueForm.value.trim() || !this.valueForm.status.trim()) {
      this.errorMessage = 'Attribute, Value, and Status are required.';
      return;
    }

    this.submitting = true;

    const selectedAttribute = this.attributes.find((item) => item.id === Number(this.valueForm.attributeId)) || null;

    const payload: AttributeValue = {
      ...this.valueForm,
      attributeId: Number(this.valueForm.attributeId),
      attributeName: selectedAttribute?.attributeName || '',
      value: this.valueForm.value.trim(),
      status: this.valueForm.status.trim(),
      attribute: selectedAttribute
    };

    this.attributeValueService.createAttributeValue(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/attributes/values']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create attribute value.';
      }
    });
  }

  onReset(): void {
    this.valueForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/attributes/values']);
  }

  private createInitialForm(): AttributeValue {
    return {
      id: 0,
      attributeId: 0,
      attributeName: '',
      value: '',
      status: 'Active',
      createdAt: '',
      updatedAt: '',
      attribute: null
    };
  }
}
