"use client";

import { Card } from "@/components/ui/card";
import type { ChartPoint } from "@/types";
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

export function ChartCard({
  title,
  data,
  dataKey,
  stroke,
}: {
  title: string;
  data: ChartPoint[];
  dataKey: "users" | "engagement";
  stroke: string;
}) {
  return (
    <Card className="h-[320px]">
      <h3 className="mb-4 text-base font-semibold">{title}</h3>
      <ResponsiveContainer width="100%" height="90%">
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" opacity={0.25} />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Line type="monotone" dataKey={dataKey} stroke={stroke} strokeWidth={3} dot={false} />
        </LineChart>
      </ResponsiveContainer>
    </Card>
  );
}
