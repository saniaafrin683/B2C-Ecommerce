import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Role } from '../role.model';
import { RoleService } from '../role.service';

@Component({
  selector: 'app-list-role',
  templateUrl: './list-role.component.html',
  styleUrls: ['./list-role.component.css']
})
export class ListRoleComponent implements OnInit {
  roles: Role[] = [];
  loading = false;
  errorMessage = '';

  constructor(
    private roleService: RoleService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadRoles();
  }

  loadRoles(): void {
    this.loading = true;
    this.errorMessage = '';

    this.roleService.getRoles().subscribe({
      next: (roles) => {
        this.roles = roles || [];
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load roles.';
      }
    });
  }

  onCreate(): void {
    this.router.navigate(['/roles/create']);
  }

  onEdit(role: Role): void {
    this.router.navigate(['/roles/edit', role.id]);
  }

  onDetails(role: Role): void {
    this.router.navigate(['/roles/details', role.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this role?');
    if (!confirmed) {
      return;
    }

    this.roleService.deleteRole(id).subscribe({
      next: () => this.loadRoles(),
      error: () => {
        this.errorMessage = 'Failed to delete role.';
      }
    });
  }

  getStatusClass(status: string): string {
    return (status || '').toUpperCase() === 'ACTIVE' ? 'pill-success' : 'pill-danger';
  }
}
