import { Input } from "@/components/ui/input";

export function SearchFilterBar({
  search,
  status,
  onSearchChange,
  onStatusChange,
}: {
  search: string;
  status: string;
  onSearchChange: (value: string) => void;
  onStatusChange: (value: string) => void;
}) {
  return (
    <div className="mb-4 grid gap-3 md:grid-cols-[1fr_180px]">
      <Input
        placeholder="Search users by name or email..."
        value={search}
        onChange={(e) => onSearchChange(e.target.value)}
      />
      <select
        className="focus-ring rounded-xl border border-border-soft bg-white/60 px-3 py-2 text-sm dark:bg-slate-900/45"
        value={status}
        onChange={(e) => onStatusChange(e.target.value)}
      >
        <option value="all">All Status</option>
        <option value="active">Active</option>
        <option value="blocked">Blocked</option>
      </select>
    </div>
  );
}
