"use client";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/common/page-header";
import { toast } from "sonner";

export default function WorkoutsPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Workout Management" description="Create and edit day-wise workout plans." />
      <Card className="space-y-3">
        <Input placeholder="Plan name (e.g. Fat Loss Pro)" />
        <div className="grid gap-3 md:grid-cols-3">
          <Input placeholder="Monday focus" />
          <Input placeholder="Tuesday focus" />
          <Input placeholder="Wednesday focus" />
        </div>
        <Button onClick={() => toast.success("Workout plan saved")}>Save Workout Plan</Button>
      </Card>
    </div>
  );
}
