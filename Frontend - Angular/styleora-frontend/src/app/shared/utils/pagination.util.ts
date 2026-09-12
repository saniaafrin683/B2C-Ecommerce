export function getTotalPages(totalItems: number, pageSize: number): number {
  return Math.max(1, Math.ceil(Math.max(totalItems, 0) / Math.max(pageSize, 1)));
}

export function clampPage(page: number, totalPages: number): number {
  return Math.min(Math.max(page, 1), Math.max(totalPages, 1));
}

export function getPaginatedItems<T>(items: T[], currentPage: number, pageSize: number): T[] {
  const safeItems = items || [];
  const safePageSize = Math.max(pageSize, 1);
  const safePage = clampPage(currentPage, getTotalPages(safeItems.length, safePageSize));
  const startIndex = (safePage - 1) * safePageSize;

  return safeItems.slice(startIndex, startIndex + safePageSize);
}

export function getVisiblePages(currentPage: number, totalPages: number, maxVisible = 5): number[] {
  const safeTotalPages = Math.max(totalPages, 1);
  const safeCurrentPage = clampPage(currentPage, safeTotalPages);
  const safeMaxVisible = Math.max(maxVisible, 1);

  if (safeTotalPages <= safeMaxVisible) {
    return Array.from({ length: safeTotalPages }, (_, index) => index + 1);
  }

  const halfWindow = Math.floor(safeMaxVisible / 2);
  let startPage = Math.max(1, safeCurrentPage - halfWindow);
  let endPage = startPage + safeMaxVisible - 1;

  if (endPage > safeTotalPages) {
    endPage = safeTotalPages;
    startPage = endPage - safeMaxVisible + 1;
  }

  return Array.from({ length: endPage - startPage + 1 }, (_, index) => startPage + index);
}
