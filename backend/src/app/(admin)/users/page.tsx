"use client";

import { useState } from "react";
import { useUsers, useBlockUser } from "@/hooks/useUsers";
import { PageHeader } from "@/components/common/page-header";
import { SearchFilterBar } from "@/components/common/search-filter-bar";
import { UsersTable } from "@/components/common/data-table";
import { Pagination } from "@/components/common/pagination";
import { Card } from "@/components/ui/card";
import type { UserItem } from "@/types";

export default function UsersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const query = { page, pageSize: 10, search };
  const { data, isLoading } = useUsers(query);
  const blockUser = useBlockUser(query);

  const rows = data?.items ?? [];

  const onBlock = async (user: UserItem) => {
    await blockUser.mutateAsync(user.id);
  };

  return (
    <div className="space-y-4">
      <PageHeader title="Users" description="Manage, search, and block users." />
      <SearchFilterBar
        search={search}
        status="all"
        onSearchChange={(value) => {
          setSearch(value);
          setPage(1);
        }}
        onStatusChange={() => undefined}
      />
      {isLoading ? (
        <Card>Loading users...</Card>
      ) : (
        <>
          <UsersTable rows={rows} onView={() => undefined} onBlock={onBlock} />
          <Pagination
            page={data?.page ?? 1}
            total={data?.total ?? 0}
            pageSize={data?.limit ?? 10}
            onChange={setPage}
          />
        </>
      )}
    </div>
  );
}
