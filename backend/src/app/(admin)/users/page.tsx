"use client";

import { useMemo, useState } from "react";
import type { ColumnDef, SortingState } from "@tanstack/react-table";
import {
  useUsers,
  useBlockUser,
  useUnblockUser,
  useUserDetails,
  useUserProgress,
} from "@/hooks/useUsers";
import type { UsersQuery } from "@/hooks/useUsers";
import { PageHeader } from "@/components/common/page-header";
import { DataTable } from "@/components/common/data-table";
import { EmptyState, TableSkeleton } from "@/components/common/state";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Pagination } from "@/components/common/pagination";
import type { UserItem } from "@/types";

// ─── Constants ────────────────────────────────────────────────────────────────

const GOALS = ["Loss weight", "Lift & tone", "Lose belly fat", "Build muscles"];
const FITNESS_LEVELS = ["Beginner", "Intermediate", "Advanced"];

const SELECT_CLS =
  "focus-ring h-9 rounded-lg border border-input bg-surface px-3 text-sm text-foreground";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function Avatar({ user }: { user: UserItem }) {
  if (user.photoUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={user.photoUrl}
        alt=""
        className="h-8 w-8 shrink-0 rounded-full object-cover"
      />
    );
  }
  return (
    <div className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-primary/10 text-sm font-bold text-primary">
      {user.name?.[0]?.toUpperCase() ?? "?"}
    </div>
  );
}

type BadgeTone = "default" | "primary" | "success" | "warning" | "danger" | "info";

function goalTone(goal?: string | null): BadgeTone {
  if (!goal) return "default";
  const g = goal.toLowerCase();
  if (g.includes("loss") || g.includes("lose")) return "danger";
  if (g.includes("tone")) return "primary";
  if (g.includes("build")) return "info";
  return "warning";
}

function levelTone(level?: string | null): BadgeTone {
  if (level === "Beginner") return "success";
  if (level === "Intermediate") return "warning";
  if (level === "Advanced") return "primary";
  return "default";
}

const Dash = () => <span className="text-xs text-muted-foreground">—</span>;

// ─── User Detail Drawer ──────────────────────────────────────────────────────

function LabelValue({ label, value }: { label: string; value?: string | number | null }) {
  if (value == null || value === "") return null;
  return (
    <div>
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="text-sm font-medium text-foreground">{String(value)}</p>
    </div>
  );
}

function UserDetailDrawer({ userId, onClose }: { userId: string; onClose: () => void }) {
  const { data: user, isLoading: loadingUser } = useUserDetails(userId);
  const { data: progress, isLoading: loadingProgress } = useUserProgress(userId);

  return (
    <div className="fixed inset-0 z-40 flex">
      <div className="flex-1 bg-black/40" onClick={onClose} />
      <div className="relative flex h-full w-full max-w-md flex-col overflow-y-auto border-l border-border bg-surface shadow-2xl">
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-border bg-surface px-5 py-4">
          <h2 className="font-semibold text-foreground">User detail</h2>
          <Button variant="ghost" size="icon" onClick={onClose} aria-label="Close">
            ✕
          </Button>
        </div>

        {loadingUser ? (
          <div className="flex flex-1 items-center justify-center text-sm text-muted-foreground">
            Loading…
          </div>
        ) : user ? (
          <div className="space-y-6 p-5">
            <div className="flex items-center gap-4">
              {user.photoUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={user.photoUrl}
                  alt=""
                  className="h-14 w-14 rounded-full object-cover"
                />
              ) : (
                <div className="grid h-14 w-14 place-items-center rounded-full bg-primary/10 text-xl font-bold text-primary">
                  {user.name?.[0]?.toUpperCase() ?? "?"}
                </div>
              )}
              <div>
                <p className="font-semibold text-foreground">{user.name}</p>
                <p className="text-xs text-muted-foreground">{user.email}</p>
                <Badge variant={user.isBlocked ? "danger" : "success"} className="mt-1">
                  {user.isBlocked ? "Blocked" : "Active"}
                </Badge>
              </div>
            </div>

            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Account
              </p>
              <div className="grid grid-cols-2 gap-3">
                <LabelValue label="Joined" value={user.joinedAt} />
                <LabelValue
                  label="Firebase UID"
                  value={user.firebaseUid ? "Connected" : "Not set"}
                />
              </div>
            </div>

            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Onboarding profile
              </p>
              <div className="grid grid-cols-2 gap-3">
                <LabelValue label="Fitness level" value={user.fitnessLevel} />
                <LabelValue label="Goal" value={user.goal} />
                <LabelValue label="Diet style" value={user.dietStyle} />
                <LabelValue
                  label="Target weight"
                  value={user.targetWeight ? `${user.targetWeight} kg` : null}
                />
                <LabelValue label="Height" value={user.height ? `${user.height} cm` : null} />
                <LabelValue label="Weight" value={user.weight ? `${user.weight} kg` : null} />
                <LabelValue
                  label="Date of birth"
                  value={user.dob ? new Date(user.dob).toLocaleDateString() : null}
                />
                <LabelValue label="Focus areas" value={user.focusAreas?.join(", ")} />
              </div>
            </div>

            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Workout progress
              </p>
              {loadingProgress ? (
                <p className="text-xs text-muted-foreground">Loading progress…</p>
              ) : progress ? (
                <>
                  <div className="mb-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
                    {[
                      { v: progress.stats.totalSessions, l: "Sessions" },
                      { v: progress.stats.totalCalories, l: "kcal" },
                      { v: progress.stats.totalMinutes, l: "min" },
                    ].map(({ v, l }) => (
                      <div key={l} className="rounded-xl bg-muted p-3 text-center">
                        <p className="text-xl font-bold text-foreground">{v}</p>
                        <p className="text-xs text-muted-foreground">{l}</p>
                      </div>
                    ))}
                    <div className="rounded-xl bg-primary/10 p-3 text-center">
                      <p className="text-xl font-bold text-primary">
                        {progress.stats.streak ?? 0} 🔥
                      </p>
                      <p className="text-xs text-muted-foreground">Day streak</p>
                    </div>
                  </div>
                  {progress.completions.length > 0 && (
                    <div className="space-y-1.5">
                      <p className="text-xs text-muted-foreground">Recent completions</p>
                      {progress.completions.slice(0, 8).map((c) => (
                        <div
                          key={c.id}
                          className="flex items-center justify-between rounded-lg bg-muted px-3 py-2 text-xs"
                        >
                          <span className="font-medium text-foreground">
                            Day {c.workoutDay.dayNumber} — {c.workoutDay.title}
                          </span>
                          <span className="text-muted-foreground">
                            {new Date(c.completedAt).toLocaleDateString()}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </>
              ) : (
                <p className="text-xs text-muted-foreground">No progress recorded.</p>
              )}
            </div>
          </div>
        ) : (
          <div className="flex flex-1 items-center justify-center text-sm text-muted-foreground">
            User not found.
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type SortField = "name" | "email" | "createdAt" | "goal" | "fitnessLevel";

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

  const rows = useMemo(() => data?.items ?? [], [data]);

  // TanStack's sorting shape adapted to the API's sortBy/sortDir pair. Sorting
  // is server-side, so this only ever tells the query what to ask for.
  const sorting: SortingState = [{ id: sortBy, desc: sortDir === "desc" }];

  const onSortingChange = (updater: React.SetStateAction<SortingState>) => {
    const next = typeof updater === "function" ? updater(sorting) : updater;
    if (next.length === 0) return;
    setSortBy(next[0].id as SortField);
    setSortDir(next[0].desc ? "desc" : "asc");
    setPage(1);
  };

  const columns = useMemo<ColumnDef<UserItem>[]>(
    () => [
      {
        id: "name",
        accessorKey: "name",
        header: "User",
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex items-center gap-3">
            <Avatar user={row.original} />
            <span className="font-medium text-foreground">{row.original.name}</span>
          </div>
        ),
      },
      {
        id: "email",
        accessorKey: "email",
        header: "Email",
        cell: ({ row }) => (
          <span className="text-muted-foreground">{row.original.email}</span>
        ),
      },
      {
        id: "goal",
        accessorKey: "goal",
        header: "Goal",
        cell: ({ row }) =>
          row.original.goal ? (
            <Badge variant={goalTone(row.original.goal)}>{row.original.goal}</Badge>
          ) : (
            <Dash />
          ),
      },
      {
        id: "fitnessLevel",
        accessorKey: "fitnessLevel",
        header: "Level",
        cell: ({ row }) =>
          row.original.fitnessLevel ? (
            <Badge variant={levelTone(row.original.fitnessLevel)}>
              {row.original.fitnessLevel}
            </Badge>
          ) : (
            <Dash />
          ),
      },
      {
        id: "status",
        header: "Status",
        // Server has no `status` sort key — offering one would silently do nothing.
        enableSorting: false,
        cell: ({ row }) => (
          <Badge variant={row.original.isBlocked ? "danger" : "success"}>
            {row.original.isBlocked ? "Blocked" : "Active"}
          </Badge>
        ),
      },
      {
        id: "createdAt",
        accessorKey: "joinedAt",
        header: "Joined",
        cell: ({ row }) => (
          <span className="whitespace-nowrap text-muted-foreground">
            {row.original.joinedAt}
          </span>
        ),
      },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => {
          const user = row.original;
          return (
            <div className="flex items-center gap-1.5">
              <Button variant="ghost" size="sm" onClick={() => setSelectedId(user.id)}>
                View
              </Button>
              {user.isBlocked ? (
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={() => unblockUser.mutate(user.id)}
                >
                  Unblock
                </Button>
              ) : (
                <Button variant="danger" size="sm" onClick={() => blockUser.mutate(user.id)}>
                  Block
                </Button>
              )}
            </div>
          );
        },
      },
    ],
    [blockUser, unblockUser],
  );

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

      <Card className="flex flex-wrap items-center gap-3">
        <form
          onSubmit={handleSearchSubmit}
          className="flex min-w-[220px] flex-1 items-center gap-2"
        >
          <Input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Search name or email…"
            className="flex-1"
            aria-label="Search users"
          />
          <Button type="submit" variant="secondary">
            Search
          </Button>
        </form>

        <select
          value={status}
          aria-label="Filter by status"
          onChange={(e) => {
            setStatus(e.target.value as "all" | "active" | "blocked");
            setPage(1);
          }}
          className={SELECT_CLS}
        >
          <option value="all">All statuses</option>
          <option value="active">Active</option>
          <option value="blocked">Blocked</option>
        </select>

        <select
          value={goal}
          aria-label="Filter by goal"
          onChange={(e) => {
            setGoal(e.target.value);
            setPage(1);
          }}
          className={SELECT_CLS}
        >
          <option value="">All goals</option>
          {GOALS.map((g) => (
            <option key={g} value={g}>
              {g}
            </option>
          ))}
        </select>

        <select
          value={fitnessLevel}
          aria-label="Filter by fitness level"
          onChange={(e) => {
            setFitnessLevel(e.target.value);
            setPage(1);
          }}
          className={SELECT_CLS}
        >
          <option value="">All levels</option>
          {FITNESS_LEVELS.map((l) => (
            <option key={l} value={l}>
              {l}
            </option>
          ))}
        </select>

        {hasFilters && (
          <Button variant="ghost" size="sm" onClick={clearFilters}>
            Clear filters
          </Button>
        )}
      </Card>

      {isLoading ? (
        <TableSkeleton rows={8} />
      ) : (
        <>
          <DataTable
            columns={columns}
            data={rows}
            sorting={sorting}
            onSortingChange={onSortingChange}
            getRowId={(row) => row.id}
            minWidth={900}
            emptyState={
              <EmptyState
                title="No users found"
                description={
                  hasFilters
                    ? "No users match the current filters."
                    : "Users appear here once people sign up in the mobile app."
                }
                action={
                  hasFilters ? (
                    <Button variant="secondary" size="sm" onClick={clearFilters}>
                      Clear filters
                    </Button>
                  ) : undefined
                }
              />
            }
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
