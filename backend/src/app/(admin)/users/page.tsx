"use client";

import { useState } from "react";
import { useUsers, useBlockUser, useUnblockUser, useUserDetails, useUserProgress } from "@/hooks/useUsers";
import type { UsersQuery } from "@/hooks/useUsers";
import { PageHeader } from "@/components/common/page-header";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Pagination } from "@/components/common/pagination";
import type { UserItem } from "@/types";

// ─── Constants ────────────────────────────────────────────────────────────────

const GOALS = ["Loss weight", "Lift & tone", "Lose belly fat", "Build muscles"];
const FITNESS_LEVELS = ["Beginner", "Intermediate", "Advanced"];

// ─── Helpers ─────────────────────────────────────────────────────────────────

function Avatar({ user }: { user: UserItem }) {
  if (user.photoUrl) {
    return (
      <img
        src={user.photoUrl}
        alt={user.name}
        className="h-8 w-8 rounded-full object-cover"
      />
    );
  }
  return (
    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-pink-100 text-sm font-bold text-pink-600 dark:bg-pink-900/30 dark:text-pink-400">
      {user.name?.[0]?.toUpperCase() ?? "?"}
    </div>
  );
}

function Badge({
  children,
  color = "slate",
}: {
  children: React.ReactNode;
  color?: "green" | "rose" | "blue" | "violet" | "amber" | "slate";
}) {
  const map = {
    green: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
    rose: "bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400",
    blue: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
    violet: "bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400",
    amber: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
    slate: "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300",
  };
  return (
    <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${map[color]}`}>
      {children}
    </span>
  );
}

function goalColor(goal?: string | null): "blue" | "violet" | "amber" | "green" | "slate" {
  if (!goal) return "slate";
  if (goal.toLowerCase().includes("loss") || goal.toLowerCase().includes("lose")) return "rose" as "slate";
  if (goal.toLowerCase().includes("tone")) return "violet";
  if (goal.toLowerCase().includes("build")) return "blue";
  return "amber";
}

function SortIcon({ active, dir }: { active: boolean; dir: "asc" | "desc" }) {
  if (!active) return <span className="ml-1 text-slate-300">↕</span>;
  return <span className="ml-1 text-blue-500">{dir === "asc" ? "↑" : "↓"}</span>;
}

// ─── User Detail Drawer ──────────────────────────────────────────────────────

function LabelValue({ label, value }: { label: string; value?: string | number | null }) {
  if (value == null || value === "") return null;
  return (
    <div>
      <p className="text-xs text-slate-400">{label}</p>
      <p className="text-sm font-medium text-slate-700 dark:text-slate-200">{String(value)}</p>
    </div>
  );
}

function UserDetailDrawer({ userId, onClose }: { userId: string; onClose: () => void }) {
  const { data: user, isLoading: loadingUser } = useUserDetails(userId);
  const { data: progress, isLoading: loadingProgress } = useUserProgress(userId);

  return (
    <div className="fixed inset-0 z-40 flex">
      <div className="flex-1 bg-black/30" onClick={onClose} />
      <div className="relative flex h-full w-full max-w-md flex-col overflow-y-auto bg-white shadow-2xl dark:bg-slate-900 sm:border-l sm:border-slate-200 sm:dark:border-slate-700">
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white px-5 py-4 dark:border-slate-700 dark:bg-slate-900">
          <h2 className="font-semibold text-slate-800 dark:text-slate-100">User Detail</h2>
          <button onClick={onClose} className="text-lg text-slate-400 hover:text-slate-600">✕</button>
        </div>

        {loadingUser ? (
          <div className="flex flex-1 items-center justify-center text-sm text-slate-400">Loading…</div>
        ) : user ? (
          <div className="space-y-6 p-5">
            {/* Avatar + basic */}
            <div className="flex items-center gap-4">
              {user.photoUrl ? (
                <img src={user.photoUrl} alt={user.name} className="h-14 w-14 rounded-full object-cover" />
              ) : (
                <div className="flex h-14 w-14 items-center justify-center rounded-full bg-pink-100 text-xl font-bold text-pink-600 dark:bg-pink-900/30">
                  {user.name?.[0]?.toUpperCase() ?? "?"}
                </div>
              )}
              <div>
                <p className="font-semibold text-slate-800 dark:text-slate-100">{user.name}</p>
                <p className="text-xs text-slate-500">{user.email}</p>
                <span className={`mt-1 inline-block rounded-full px-2 py-0.5 text-xs font-medium ${user.isBlocked ? "bg-rose-100 text-rose-700" : "bg-green-100 text-green-700"}`}>
                  {user.isBlocked ? "Blocked" : "Active"}
                </span>
              </div>
            </div>

            {/* Account */}
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Account</p>
              <div className="grid grid-cols-2 gap-3">
                <LabelValue label="Joined" value={user.joinedAt} />
                <LabelValue label="Firebase UID" value={user.firebaseUid ? "Connected" : "Not set"} />
              </div>
            </div>

            {/* Onboarding profile */}
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Onboarding Profile</p>
              <div className="grid grid-cols-2 gap-3">
                <LabelValue label="Fitness level" value={user.fitnessLevel} />
                <LabelValue label="Goal" value={user.goal} />
                <LabelValue label="Diet style" value={user.dietStyle} />
                <LabelValue label="Target weight" value={user.targetWeight ? `${user.targetWeight} kg` : null} />
                <LabelValue label="Height" value={user.height ? `${user.height} cm` : null} />
                <LabelValue label="Weight" value={user.weight ? `${user.weight} kg` : null} />
                <LabelValue label="Date of birth" value={user.dob ? new Date(user.dob).toLocaleDateString() : null} />
                <LabelValue label="Focus areas" value={user.focusAreas?.join(", ")} />
              </div>
            </div>

            {/* Progress */}
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Workout Progress</p>
              {loadingProgress ? (
                <p className="text-xs text-slate-400">Loading progress…</p>
              ) : progress ? (
                <>
                  <div className="mb-3 grid grid-cols-3 gap-2">
                    <div className="rounded-xl bg-slate-50 p-3 text-center dark:bg-slate-800">
                      <p className="text-xl font-bold text-slate-800 dark:text-slate-100">{progress.stats.totalSessions}</p>
                      <p className="text-xs text-slate-400">Sessions</p>
                    </div>
                    <div className="rounded-xl bg-slate-50 p-3 text-center dark:bg-slate-800">
                      <p className="text-xl font-bold text-slate-800 dark:text-slate-100">{progress.stats.totalCalories}</p>
                      <p className="text-xs text-slate-400">kcal</p>
                    </div>
                    <div className="rounded-xl bg-slate-50 p-3 text-center dark:bg-slate-800">
                      <p className="text-xl font-bold text-slate-800 dark:text-slate-100">{progress.stats.totalMinutes}</p>
                      <p className="text-xs text-slate-400">min</p>
                    </div>
                  </div>
                  {progress.completions.length > 0 && (
                    <div className="space-y-1.5">
                      <p className="text-xs text-slate-400">Recent completions</p>
                      {progress.completions.slice(0, 8).map((c) => (
                        <div key={c.id} className="flex items-center justify-between rounded-lg bg-slate-50 px-3 py-2 text-xs dark:bg-slate-800">
                          <span className="font-medium text-slate-700 dark:text-slate-200">
                            Day {c.workoutDay.dayNumber} — {c.workoutDay.title}
                          </span>
                          <span className="text-slate-400">{new Date(c.completedAt).toLocaleDateString()}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </>
              ) : (
                <p className="text-xs text-slate-400">No progress recorded.</p>
              )}
            </div>
          </div>
        ) : (
          <div className="flex flex-1 items-center justify-center text-sm text-slate-400">User not found.</div>
        )}
      </div>
    </div>
  );
}

// ─── Table ────────────────────────────────────────────────────────────────────

type SortField = "name" | "email" | "createdAt" | "goal" | "fitnessLevel";

function SortableTh({
  field,
  label,
  sortBy,
  sortDir,
  onSort,
}: {
  field: SortField;
  label: string;
  sortBy: SortField;
  sortDir: "asc" | "desc";
  onSort: (f: SortField) => void;
}) {
  const active = sortBy === field;
  return (
    <th
      className="cursor-pointer select-none whitespace-nowrap px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
      onClick={() => onSort(field)}
    >
      {label}
      <SortIcon active={active} dir={sortDir} />
    </th>
  );
}

function UsersDataTable({
  rows,
  sortBy,
  sortDir,
  onSort,
  onView,
  onBlock,
  onUnblock,
}: {
  rows: UserItem[];
  sortBy: SortField;
  sortDir: "asc" | "desc";
  onSort: (f: SortField) => void;
  onView: (u: UserItem) => void;
  onBlock: (u: UserItem) => void;
  onUnblock: (u: UserItem) => void;
}) {
  if (rows.length === 0) {
    return (
      <Card className="py-16 text-center text-sm text-slate-400">
        No app users found.
      </Card>
    );
  }

  return (
    <Card className="overflow-auto p-0">
      <table className="w-full min-w-[900px] text-left text-sm">
        <thead className="border-b border-slate-100 dark:border-slate-800">
          <tr>
            <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              User
            </th>
            <SortableTh field="email" label="Email" sortBy={sortBy} sortDir={sortDir} onSort={onSort} />
            <SortableTh field="goal" label="Goal" sortBy={sortBy} sortDir={sortDir} onSort={onSort} />
            <SortableTh field="fitnessLevel" label="Level" sortBy={sortBy} sortDir={sortDir} onSort={onSort} />
            <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Status
            </th>
            <SortableTh field="createdAt" label="Joined" sortBy={sortBy} sortDir={sortDir} onSort={onSort} />
            <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-50 dark:divide-slate-800">
          {rows.map((user) => (
            <tr
              key={user.id}
              className="transition-colors hover:bg-slate-50/60 dark:hover:bg-slate-800/40"
            >
              {/* User */}
              <td className="px-4 py-3">
                <div className="flex items-center gap-3">
                  <Avatar user={user} />
                  <span className="font-medium text-slate-800 dark:text-slate-100">
                    {user.name}
                  </span>
                </div>
              </td>

              {/* Email */}
              <td className="px-4 py-3 text-slate-500 dark:text-slate-400">
                {user.email}
              </td>

              {/* Goal */}
              <td className="px-4 py-3">
                {user.goal ? (
                  <Badge color={goalColor(user.goal) as "blue" | "violet" | "amber" | "green" | "slate"}>
                    {user.goal}
                  </Badge>
                ) : (
                  <span className="text-xs text-slate-300">—</span>
                )}
              </td>

              {/* Fitness level */}
              <td className="px-4 py-3">
                {user.fitnessLevel ? (
                  <Badge color={user.fitnessLevel === "Beginner" ? "green" : user.fitnessLevel === "Intermediate" ? "amber" : "violet"}>
                    {user.fitnessLevel}
                  </Badge>
                ) : (
                  <span className="text-xs text-slate-300">—</span>
                )}
              </td>

              {/* Status */}
              <td className="px-4 py-3">
                <Badge color={user.isBlocked ? "rose" : "green"}>
                  {user.isBlocked ? "Blocked" : "Active"}
                </Badge>
              </td>

              {/* Joined */}
              <td className="px-4 py-3 text-slate-500 dark:text-slate-400">
                {user.joinedAt}
              </td>

              {/* Actions */}
              <td className="px-4 py-3">
                <div className="flex items-center gap-1.5">
                  <Button variant="ghost" onClick={() => onView(user)}>
                    View
                  </Button>
                  {user.isBlocked ? (
                    <Button variant="secondary" onClick={() => onUnblock(user)}>
                      Unblock
                    </Button>
                  ) : (
                    <Button variant="danger" onClick={() => onBlock(user)}>
                      Block
                    </Button>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </Card>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function UsersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const [status, setStatus] = useState<"all" | "active" | "blocked">("all");
  const [goal, setGoal] = useState("");
  const [fitnessLevel, setFitnessLevel] = useState("");
  const [sortBy, setSortBy] = useState<SortField>("createdAt");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("desc");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const query: UsersQuery = {
    page,
    pageSize: 15,
    search,
    status,
    goal,
    fitnessLevel,
    sortBy,
    sortDir,
  };

  const { data, isLoading } = useUsers(query);
  const blockUser = useBlockUser(query);
  const unblockUser = useUnblockUser(query);

  const rows = data?.items ?? [];

  function handleSort(field: SortField) {
    if (sortBy === field) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortBy(field);
      setSortDir("asc");
    }
    setPage(1);
  }

  function handleSearchSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSearch(searchInput);
    setPage(1);
  }

  function clearFilters() {
    setSearch("");
    setSearchInput("");
    setStatus("all");
    setGoal("");
    setFitnessLevel("");
    setSortBy("createdAt");
    setSortDir("desc");
    setPage(1);
  }

  const hasFilters = search || status !== "all" || goal || fitnessLevel;

  return (
    <div className="space-y-4">
      <PageHeader
        title="App Users"
        description={`${data?.total ?? 0} users registered via the mobile app`}
      />

      {/* Filter bar */}
      <Card className="flex flex-wrap items-center gap-3">
        {/* Search */}
        <form onSubmit={handleSearchSubmit} className="flex min-w-[220px] flex-1 items-center gap-2">
          <Input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Search name or email…"
            className="flex-1"
          />
          <Button type="submit" variant="secondary">
            Search
          </Button>
        </form>

        {/* Status filter */}
        <select
          value={status}
          onChange={(e) => { setStatus(e.target.value as "all" | "active" | "blocked"); setPage(1); }}
          className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 shadow-sm focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
        >
          <option value="all">All statuses</option>
          <option value="active">Active</option>
          <option value="blocked">Blocked</option>
        </select>

        {/* Goal filter */}
        <select
          value={goal}
          onChange={(e) => { setGoal(e.target.value); setPage(1); }}
          className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 shadow-sm focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
        >
          <option value="">All goals</option>
          {GOALS.map((g) => (
            <option key={g} value={g}>{g}</option>
          ))}
        </select>

        {/* Fitness level filter */}
        <select
          value={fitnessLevel}
          onChange={(e) => { setFitnessLevel(e.target.value); setPage(1); }}
          className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 shadow-sm focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
        >
          <option value="">All levels</option>
          {FITNESS_LEVELS.map((l) => (
            <option key={l} value={l}>{l}</option>
          ))}
        </select>

        {hasFilters && (
          <button
            onClick={clearFilters}
            className="text-xs text-slate-400 hover:text-rose-500"
          >
            Clear filters
          </button>
        )}
      </Card>

      {/* Table */}
      {isLoading ? (
        <Card className="py-12 text-center text-sm text-slate-400">Loading users…</Card>
      ) : (
        <>
          <UsersDataTable
            rows={rows}
            sortBy={sortBy}
            sortDir={sortDir}
            onSort={handleSort}
            onView={(u) => setSelectedId(u.id)}
            onBlock={(u) => blockUser.mutate(u.id)}
            onUnblock={(u) => unblockUser.mutate(u.id)}
          />
          <Pagination
            page={data?.page ?? 1}
            total={data?.total ?? 0}
            pageSize={data?.limit ?? 15}
            onChange={setPage}
          />
        </>
      )}

      {selectedId && (
        <UserDetailDrawer userId={selectedId} onClose={() => setSelectedId(null)} />
      )}
    </div>
  );
}
