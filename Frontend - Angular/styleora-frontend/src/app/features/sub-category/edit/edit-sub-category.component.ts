import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { Category } from '../../category/category.model';
import { CategoryService } from '../../category/category.service';
import { SubCategory } from '../sub-category.model';
import { SubCategoryService } from '../sub-category.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-edit-sub-category',
  templateUrl: './edit-sub-category.component.html',
  styleUrls: ['./edit-sub-category.component.css']
})
export class EditSubCategoryComponent implements OnInit {
  subCategoryId!: number;
  loading = false;
  loadingCategories = false;
  submitting = false;
  selectedFileName = '';

  categories: Category[] = [];
  createdByOptions: string[] = ['Seller', 'Admin', 'Other'];
  statusOptions: string[] = ['Active', 'Inactive', 'Draft'];

  subCategoryForm: SubCategory = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private subCategoryService: SubCategoryService,
    private categoryService: CategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadCategories();

    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.subCategoryId = +id;
        this.loadSubCategoryById();
      } else {
        this.notificationService.showError('Invalid sub category id.');
        this.router.navigate(['/sub-category/list']);
      }
    });
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

  loadSubCategoryById(): void {
    this.loading = true;
    this.loadingService.show();

    this.subCategoryService.getSubCategoryById(this.subCategoryId).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (subCategory) => {
        this.subCategoryForm = {
          ...subCategory,
          categoryId: subCategory.categoryId ?? null
        };
        this.selectedFileName = '';
      },
      error: () => {
        this.notificationService.showError('Failed to load sub category data.');
        this.router.navigate(['/sub-category/list']);
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

  onUpdate(): void {
    this.onCategoryChange();
    this.submitting = true;
    this.loadingService.show();

    this.subCategoryService.updateSubCategory(this.subCategoryId, this.subCategoryForm).pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Sub category updated successfully.');
        this.router.navigate(['/sub-category/list']);
      },
      error: () => {
        this.notificationService.showError('Failed to update sub category.');
      }
    });
  }

  onReset(): void {
    this.loadSubCategoryById();
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
