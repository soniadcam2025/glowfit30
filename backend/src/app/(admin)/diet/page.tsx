"use client";

import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function DietPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Diet Management" description="Build meal plans for breakfast, lunch, and dinner." />
      <Card className="space-y-3">
        <Input placeholder="Plan title" />
        <Input placeholder="Breakfast" />
        <Input placeholder="Lunch" />
        <Input placeholder="Dinner" />
        <Button onClick={() => toast.success("Meal plan saved")}>Save Meal Plan</Button>
      </Card>
    </div>
  );
}
