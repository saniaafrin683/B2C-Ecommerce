import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Role } from '../role.model';
import { RoleService } from '../role.service';

@Component({
  selector: 'app-create-role',
  templateUrl: './create-role.component.html',
  styleUrls: ['./create-role.component.css']
})
export class CreateRoleComponent {
  submitting = false;
  errorMessage = '';

  readonly statuses = ['ACTIVE', 'INACTIVE'];
  roleForm: Role = this.createInitialForm();

  constructor(
    private roleService: RoleService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.roleForm.name.trim() || !this.roleForm.status.trim()) {
      this.errorMessage = 'Role Name and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: Role = {
      ...this.roleForm,
      name: this.roleForm.name.trim(),
      description: (this.roleForm.description || '').trim(),
      status: this.roleForm.status.trim()
    };

    this.roleService.createRole(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/roles/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create role.';
      }
    });
  }

  onReset(): void {
    this.roleForm = this.createInitialForm();
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/roles/list']);
  }

  private createInitialForm(): Role {
    return {
      id: 0,
      name: '',
      description: '',
      status: 'ACTIVE'
    };
  }
}
