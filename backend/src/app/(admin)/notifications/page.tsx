"use client";

import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function NotificationsPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Notifications" description="Send push notifications to selected user segments." />
      <Card className="space-y-3">
        <Input placeholder="Notification title" />
        <textarea
          className="focus-ring min-h-[120px] w-full rounded-xl border border-border-soft bg-white/60 p-3 text-sm dark:bg-slate-900/45"
          placeholder="Notification message"
        />
        <Button onClick={() => toast.success("Push notification sent")}>Send Notification</Button>
      </Card>
    </div>
  );
}
