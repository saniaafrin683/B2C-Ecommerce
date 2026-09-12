import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Attribute } from '../attribute.model';
import { AttributeService } from '../attribute.service';

@Component({
  selector: 'app-create-attribute',
  templateUrl: './create-attribute.component.html',
  styleUrls: ['./create-attribute.component.css']
})
export class CreateAttributeComponent {
  submitting = false;
  errorMessage = '';

  readonly attributeTypes = ['Size', 'Color', 'Storage', 'RAM', 'Weight', 'Material', 'Gender', 'Condition', 'Pattern', 'Fit', 'Custom'];
  readonly statuses = ['Active', 'Inactive', 'Draft'];

  attributeForm: Attribute = this.createInitialForm();

  constructor(
    private attributeService: AttributeService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.attributeForm.attributeId.trim() ||
        !this.attributeForm.attributeName.trim() ||
        !this.attributeForm.attributeType.trim() ||
        !this.attributeForm.status.trim()) {
      this.errorMessage = 'Attribute ID, Attribute Name, Attribute Type, and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: Attribute = {
      ...this.attributeForm,
      attributeId: this.attributeForm.attributeId.trim(),
      attributeName: this.attributeForm.attributeName.trim(),
      attributeType: this.attributeForm.attributeType.trim(),
      values: (this.attributeForm.values || '').trim(),
      status: this.attributeForm.status.trim(),
      notes: (this.attributeForm.notes || '').trim()
    };

    this.attributeService.createAttribute(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/attributes/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create attribute.';
      }
    });
  }

  onReset(): void {
    this.attributeForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/attributes/list']);
  }

  private createInitialForm(): Attribute {
    return {
      id: 0,
      attributeId: '',
      attributeName: '',
      attributeType: 'Size',
      values: '',
      status: 'Active',
      createdAt: '',
      updatedAt: '',
      notes: ''
    };
  }
}
