import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Attribute } from '../attribute.model';
import { AttributeService } from '../attribute.service';

@Component({
  selector: 'app-attribute-list',
  templateUrl: './attribute-list.component.html',
  styleUrls: ['./attribute-list.component.css']
})
export class AttributeListComponent implements OnInit {
  attributes: Attribute[] = [];
  loading = false;
  errorMessage = '';

  constructor(
    private attributeService: AttributeService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadAttributes();
  }

  loadAttributes(): void {
    this.loading = true;
    this.errorMessage = '';

    this.attributeService.getAttributes().subscribe({
      next: (attributes) => {
        this.attributes = attributes || [];
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load attributes.';
      }
    });
  }

  openCreateForm(): void {
    this.router.navigate(['/attributes/create']);
  }

  onView(attribute: Attribute): void {
    this.router.navigate(['/attributes/details', attribute.id]);
  }

  onEdit(attribute: Attribute): void {
    this.router.navigate(['/attributes/edit', attribute.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this attribute?');
    if (!confirmed) {
      return;
    }

    this.attributeService.deleteAttribute(id).subscribe({
      next: () => {
        this.loadAttributes();
      },
      error: () => {
        this.errorMessage = 'Failed to delete attribute.';
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

  getValuePreview(values: string): string {
    if (!values) {
      return 'No values added';
    }

    if (values.length <= 60) {
      return values;
    }

    return `${values.slice(0, 57)}...`;
  }
}
