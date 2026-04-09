"use client";

import { useMemo, useState } from "react";

export function usePaginatedTable(defaultPageSize = 10) {
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(defaultPageSize);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");

  const query = useMemo(
    () => ({
      page,
      pageSize,
      search,
      status,
    }),
    [page, pageSize, search, status],
  );

  return { page, setPage, pageSize, setPageSize, search, setSearch, status, setStatus, query };
}
