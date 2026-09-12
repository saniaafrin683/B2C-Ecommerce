import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { CategoryService } from '../category.service';
import { Category } from '../category.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-create-category',
  templateUrl: './create-category.component.html',
  styleUrls: ['./create-category.component.css']
})
export class CreateCategoryComponent {

  submitting: boolean = false;
  selectedFileName: string = '';

  categoryForm: Category = {
    categoryTitle: '',
    createdBy: '',
    stock: 0,
    tagId: '',
    description: '',
    imageUrl: ''
  };

  createdByOptions: string[] = ['Seller', 'Admin', 'Other'];

  constructor(
    private categoryService: CategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private router: Router
  ) {}

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      this.selectedFileName = file.name;

      const reader = new FileReader();
      reader.onload = () => {
        this.categoryForm.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    } else {
      this.selectedFileName = '';
    }
  }

  onSave(): void {
    this.submitting = true;
    this.loadingService.show();

    this.categoryService.createCategory(this.categoryForm).pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Category created successfully.');
        this.router.navigate(['/category/list']);
      },
      error: () => {
        this.notificationService.showError('Failed to create category.');
      }
    });
  }

  onReset(): void {
    this.categoryForm = {
      categoryTitle: '',
      createdBy: '',
      stock: 0,
      tagId: '',
      description: '',
      imageUrl: ''
    };

    this.selectedFileName = '';
  }

  onCancel(): void {
    this.router.navigate(['/category/list']);
  }
}
