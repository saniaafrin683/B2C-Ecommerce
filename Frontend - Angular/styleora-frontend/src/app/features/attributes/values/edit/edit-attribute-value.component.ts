import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Attribute } from '../../attribute.model';
import { AttributeService } from '../../attribute.service';
import { AttributeValue } from '../attribute-value.model';
import { AttributeValueService } from '../attribute-value.service';

@Component({
  selector: 'app-edit-attribute-value',
  templateUrl: './edit-attribute-value.component.html',
  styleUrls: ['./edit-attribute-value.component.css']
})
export class EditAttributeValueComponent implements OnInit {
  valueId!: number;
  attributes: Attribute[] = [];
  loading = false;
  loadingAttributes = false;
  submitting = false;
  errorMessage = '';

  readonly statuses = ['Active', 'Inactive', 'Draft'];

  valueForm: AttributeValue = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private attributeService: AttributeService,
    private attributeValueService: AttributeValueService
  ) {}

  ngOnInit(): void {
    this.loadAttributes();

    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.valueId = +id;
        this.loadAttributeValue();
      } else {
        this.router.navigate(['/attributes/values']);
      }
    });
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

  loadAttributeValue(): void {
    this.loading = true;
    this.errorMessage = '';

    this.attributeValueService.getAttributeValueById(this.valueId).subscribe({
      next: (attributeValue) => {
        this.valueForm = attributeValue;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load attribute value.';
      }
    });
  }

  onUpdate(): void {
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

    this.attributeValueService.updateAttributeValue(this.valueId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/attributes/values']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to update attribute value.';
      }
    });
  }

  onReset(): void {
    this.loadAttributeValue();
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
