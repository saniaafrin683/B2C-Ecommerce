import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { Category } from '../../category/category.model';
import { CategoryService } from '../../category/category.service';
import { SubCategory } from '../sub-category.model';
import { SubCategoryService } from '../sub-category.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-create-sub-category',
  templateUrl: './create-sub-category.component.html',
  styleUrls: ['./create-sub-category.component.css']
})
export class CreateSubCategoryComponent implements OnInit {
  submitting = false;
  loadingCategories = false;
  selectedFileName = '';

  categories: Category[] = [];
  createdByOptions: string[] = ['Seller', 'Admin', 'Other'];
  statusOptions: string[] = ['Active', 'Inactive', 'Draft'];

  subCategoryForm: SubCategory = this.createInitialForm();

  constructor(
    private subCategoryService: SubCategoryService,
    private categoryService: CategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCategories();
  }

  loadCategories(): void {
    this.loadingCategories = true;
    this.loadingService.show();

    this.categoryService.getAllCategories().pipe(
      finalize(() => {
        this.loadingCategories = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (categories) => {
        this.categories = categories || [];
      },
      error: () => {
        this.notificationService.showWarning('Failed to load parent categories.');
      }
    });
  }

  onCategoryChange(): void {
    const selectedCategory = this.categories.find(
      (category) => category.id === this.subCategoryForm.categoryId
    );

    this.subCategoryForm.categoryName = selectedCategory?.categoryTitle || '';
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      this.selectedFileName = file.name;

      const reader = new FileReader();
      reader.onload = () => {
        this.subCategoryForm.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
      return;
    }

    this.selectedFileName = '';
  }

  onSave(): void {
    this.onCategoryChange();
    this.submitting = true;
    this.loadingService.show();

    this.subCategoryService.createSubCategory(this.subCategoryForm).pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Sub category created successfully.');
        this.router.navigate(['/sub-category/list']);
      },
      error: () => {
        this.notificationService.showError('Failed to create sub category.');
      }
    });
  }

  onReset(): void {
    this.subCategoryForm = this.createInitialForm();
    this.selectedFileName = '';
  }

  onCancel(): void {
    this.router.navigate(['/sub-category/list']);
  }

  private createInitialForm(): SubCategory {
    return {
      subCategoryCode: '',
      subCategoryName: '',
      categoryId: null,
      categoryName: '',
      createdBy: '',
      stock: 0,
      tagId: '',
      description: '',
      imageUrl: '',
      status: 'Active'
    };
  }
}
