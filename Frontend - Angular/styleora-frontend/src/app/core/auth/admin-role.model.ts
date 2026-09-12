export type AdminRole = 'ADMIN' | 'MODERATOR' | 'SALES';

export const ADMIN_ONLY_ROLES: AdminRole[] = ['ADMIN'];
export const DASHBOARD_ACCESS_ROLES: AdminRole[] = ['ADMIN', 'MODERATOR', 'SALES'];
export const CUSTOMER_VIEW_ROLES: AdminRole[] = ['ADMIN', 'MODERATOR', 'SALES'];
export const ORDER_VIEW_ROLES: AdminRole[] = ['ADMIN', 'MODERATOR', 'SALES'];
export const ORDER_MANAGE_ROLES: AdminRole[] = ['ADMIN', 'SALES'];
export const MODERATION_ACCESS_ROLES: AdminRole[] = ['ADMIN', 'MODERATOR'];
export const SALES_ACCESS_ROLES: AdminRole[] = ['ADMIN', 'SALES'];

export function normalizeAdminRole(role: string | null | undefined): AdminRole {
  const normalizedRole = (role || '').trim().toUpperCase();

  if (normalizedRole === 'MODERATOR' || normalizedRole === 'SALES') {
    return normalizedRole;
  }

  return 'ADMIN';
}
