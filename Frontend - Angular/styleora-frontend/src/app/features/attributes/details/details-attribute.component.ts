import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Attribute } from '../attribute.model';
import { AttributeService } from '../attribute.service';

@Component({
  selector: 'app-details-attribute',
  templateUrl: './details-attribute.component.html',
  styleUrls: ['./details-attribute.component.css']
})
export class DetailsAttributeComponent implements OnInit {
  attributeId!: number;
  loading = false;
  errorMessage = '';
  attribute: Attribute | null = null;

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
        this.attribute = attribute;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load attribute details.';
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

  onEdit(): void {
    this.router.navigate(['/attributes/edit', this.attributeId]);
  }

  onBack(): void {
    this.router.navigate(['/attributes/list']);
  }
}
