import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AttributeValue } from '../attribute-value.model';
import { AttributeValueService } from '../attribute-value.service';

@Component({
  selector: 'app-attribute-value-list',
  templateUrl: './attribute-value-list.component.html',
  styleUrls: ['./attribute-value-list.component.css']
})
export class AttributeValueListComponent implements OnInit {
  attributeValues: AttributeValue[] = [];
  selectedValue: AttributeValue | null = null;
  loading = false;
  errorMessage = '';

  constructor(
    private attributeValueService: AttributeValueService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadAttributeValues();
  }

  loadAttributeValues(): void {
    this.loading = true;
    this.errorMessage = '';

    this.attributeValueService.getAttributeValues().subscribe({
      next: (values) => {
        this.attributeValues = values || [];
        this.loading = false;

        if (this.selectedValue) {
          this.selectedValue = this.attributeValues.find((item) => item.id === this.selectedValue?.id) || null;
        }
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load attribute values.';
      }
    });
  }

  onCreate(): void {
    this.router.navigate(['/attributes/values/create']);
  }

  onView(attributeValue: AttributeValue): void {
    this.selectedValue = attributeValue;
    this.errorMessage = '';
  }

  onEdit(attributeValue: AttributeValue): void {
    this.router.navigate(['/attributes/values/edit', attributeValue.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this attribute value?');
    if (!confirmed) {
      return;
    }

    this.attributeValueService.deleteAttributeValue(id).subscribe({
      next: () => {
        if (this.selectedValue?.id === id) {
          this.selectedValue = null;
        }
        this.loadAttributeValues();
      },
      error: () => {
        this.errorMessage = 'Failed to delete attribute value.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('active')) {
      return 'pill-success';
    }
    if (normalized.includes('inactive')) {
      return 'pill-danger';
    }
    return 'pill-warning';
  }
}
