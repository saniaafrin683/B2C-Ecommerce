import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Role } from '../role.model';
import { RoleService } from '../role.service';

@Component({
  selector: 'app-edit-role',
  templateUrl: './edit-role.component.html',
  styleUrls: ['./edit-role.component.css']
})
export class EditRoleComponent implements OnInit {
  roleId!: number;
  loading = false;
  submitting = false;
  errorMessage = '';
  private initialFormSnapshot: Role = this.createInitialForm();

  readonly statuses = ['ACTIVE', 'INACTIVE'];
  roleForm: Role = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private roleService: RoleService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.roleId = +id;
        this.loadRole();
      } else {
        this.router.navigate(['/roles/list']);
      }
    });
  }

  loadRole(): void {
    this.loading = true;
    this.errorMessage = '';

    this.roleService.getRoleById(this.roleId).subscribe({
      next: (role) => {
        this.roleForm = { ...role };
        this.initialFormSnapshot = { ...this.roleForm };
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load role.';
      }
    });
  }

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

    this.roleService.updateRole(this.roleId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/roles/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to update role.';
      }
    });
  }

  onReset(): void {
    this.roleForm = { ...this.initialFormSnapshot };
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
