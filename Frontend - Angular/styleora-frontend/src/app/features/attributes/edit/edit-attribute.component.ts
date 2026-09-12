import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Attribute } from '../attribute.model';
import { AttributeService } from '../attribute.service';

@Component({
  selector: 'app-edit-attribute',
  templateUrl: './edit-attribute.component.html',
  styleUrls: ['./edit-attribute.component.css']
})
export class EditAttributeComponent implements OnInit {
  attributeId!: number;
  loading = false;
  submitting = false;
  errorMessage = '';

  readonly attributeTypes = ['Size', 'Color', 'Storage', 'RAM', 'Weight', 'Material', 'Gender', 'Condition', 'Pattern', 'Fit', 'Custom'];
  readonly statuses = ['Active', 'Inactive', 'Draft'];

  attributeForm: Attribute = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private attributeService: AttributeService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.attributeId = +id;
        this.loadAttribute();
      } else {
        this.router.navigate(['/attributes/list']);
      }
    });
  }

  loadAttribute(): void {
    this.loading = true;
    this.errorMessage = '';

    this.attributeService.getAttributeById(this.attributeId).subscribe({
      next: (attribute) => {
        this.attributeForm = attribute;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load attribute.';
      }
    });
  }

  onUpdate(): void {
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

    this.attributeService.updateAttribute(this.attributeId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/attributes/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to update attribute.';
      }
    });
  }

  onReset(): void {
    this.loadAttribute();
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
