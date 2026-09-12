import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Role } from '../role.model';
import { RoleService } from '../role.service';

@Component({
  selector: 'app-details-role',
  templateUrl: './details-role.component.html',
  styleUrls: ['./details-role.component.css']
})
export class DetailsRoleComponent implements OnInit {
  roleId!: number;
  loading = false;
  errorMessage = '';
  role: Role | null = null;

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
        this.role = role;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load role details.';
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/roles/list']);
  }

  onEdit(): void {
    this.router.navigate(['/roles/edit', this.roleId]);
  }

  getStatusClass(status: string): string {
    return (status || '').toUpperCase() === 'ACTIVE' ? 'pill-success' : 'pill-danger';
  }
}
