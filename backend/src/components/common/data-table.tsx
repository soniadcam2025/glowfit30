"use client";

import * as React from "react";
import {
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
  type ColumnDef,
  type SortingState,
  type VisibilityState,
  type RowSelectionState,
} from "@tanstack/react-table";
import { ArrowDown, ArrowUp, ChevronsUpDown, Columns3 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

/**
 * Generic table built on TanStack Table.
 *
 * Replaces the previous `UsersTable`, which was hardcoded to one row shape and
 * — despite living in this file — was imported by nothing; the users page kept
 * its own inline copy.
 *
 * Sorting is *manual* when controlled, because pages using this fetch one page
 * at a time from the API. Sorting client-side would silently reorder only the
 * current page while appearing to sort the whole dataset.
 */
export interface DataTableProps<TData> {
  // TanStack's ColumnDef is invariant in its value type, so `unknown` or
  // `never` here make every concrete column definition unassignable.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  columns: ColumnDef<TData, any>[];
  data: TData[];
  /** Lift sorting to the server. Omit for local sorting. */
  sorting?: SortingState;
  onSortingChange?: (updater: React.SetStateAction<SortingState>) => void;
  manualSorting?: boolean;
  /** Client-side quick filter across visible cells. */
  globalFilter?: string;
  enableRowSelection?: boolean;
  onRowSelectionChange?: (rows: TData[]) => void;
  /** Rendered instead of the table when there are no rows. */
  emptyState?: React.ReactNode;
  /** Width below which the table scrolls horizontally rather than squashing. */
  minWidth?: number;
  getRowId?: (row: TData, index: number) => string;
  className?: string;
}

export function DataTable<TData>({
  columns,
  data,
  sorting,
  onSortingChange,
  manualSorting = true,
  globalFilter,
  enableRowSelection = false,
  onRowSelectionChange,
  emptyState,
  minWidth = 900,
  getRowId,
  className,
}: DataTableProps<TData>) {
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({});
  const [rowSelection, setRowSelection] = React.useState<RowSelectionState>({});
  const [localSorting, setLocalSorting] = React.useState<SortingState>([]);

  const isControlled = sorting !== undefined && onSortingChange !== undefined;

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting: isControlled ? sorting : localSorting,
      columnVisibility,
      rowSelection,
      globalFilter,
    },
    getRowId,
    enableRowSelection,
    manualSorting: isControlled ? manualSorting : false,
    onSortingChange: isControlled
      ? (onSortingChange as never)
      : (setLocalSorting as never),
    onColumnVisibilityChange: setColumnVisibility,
    onRowSelectionChange: setRowSelection,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: isControlled ? undefined : getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  const selectedRows = table.getSelectedRowModel().rows;

  // Report selection upward so the parent never deals with row-index keys.
  React.useEffect(() => {
    onRowSelectionChange?.(selectedRows.map((r) => r.original));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rowSelection]);

  const hideableColumns = table.getAllLeafColumns().filter((c) => c.getCanHide());

  if (data.length === 0 && emptyState) return <>{emptyState}</>;

  return (
    <div className={cn("space-y-2", className)}>
      {hideableColumns.length > 0 && (
        <div className="flex justify-end">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="secondary" size="sm">
                <Columns3 className="h-3.5 w-3.5" />
                Columns
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Visible columns</DropdownMenuLabel>
              <DropdownMenuSeparator />
              {hideableColumns.map((column) => (
                <DropdownMenuCheckboxItem
                  key={column.id}
                  checked={column.getIsVisible()}
                  onCheckedChange={(v) => column.toggleVisibility(!!v)}
                  onSelect={(e) => e.preventDefault()}
                >
                  {typeof column.columnDef.header === "string"
                    ? column.columnDef.header
                    : column.id}
                </DropdownMenuCheckboxItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      )}

      <Card className="overflow-hidden p-0">
        {/* Scrolls horizontally rather than squashing columns on narrow screens. */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm" style={{ minWidth }}>
            <thead className="sticky top-0 z-10 bg-surface-2">
              {table.getHeaderGroups().map((headerGroup) => (
                <tr key={headerGroup.id} className="border-b border-border">
                  {headerGroup.headers.map((header) => {
                    const canSort = header.column.getCanSort();
                    const dir = header.column.getIsSorted();
                    return (
                      <th
                        key={header.id}
                        scope="col"
                        aria-sort={
                          dir === "asc"
                            ? "ascending"
                            : dir === "desc"
                              ? "descending"
                              : undefined
                        }
                        className="px-4 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground"
                      >
                        {header.isPlaceholder ? null : canSort ? (
                          <button
                            type="button"
                            onClick={header.column.getToggleSortingHandler()}
                            className="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                          >
                            {flexRender(header.column.columnDef.header, header.getContext())}
                            {dir === "asc" ? (
                              <ArrowUp className="h-3 w-3 text-primary" />
                            ) : dir === "desc" ? (
                              <ArrowDown className="h-3 w-3 text-primary" />
                            ) : (
                              <ChevronsUpDown className="h-3 w-3 opacity-40" />
                            )}
                          </button>
                        ) : (
                          flexRender(header.column.columnDef.header, header.getContext())
                        )}
                      </th>
                    );
                  })}
                </tr>
              ))}
            </thead>
            <tbody>
              {table.getRowModel().rows.map((row) => (
                <tr
                  key={row.id}
                  data-state={row.getIsSelected() ? "selected" : undefined}
                  className="border-b border-border transition-colors last:border-0 hover:bg-muted/50 data-[state=selected]:bg-primary/5"
                >
                  {row.getVisibleCells().map((cell) => (
                    <td key={cell.id} className="px-4 py-3 align-middle">
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {enableRowSelection && selectedRows.length > 0 && (
        <p className="text-xs text-muted-foreground">
          {selectedRows.length} of {data.length} row(s) selected
        </p>
      )}
    </div>
  );
}
