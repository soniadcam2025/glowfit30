"use client";

import { useState } from "react";
import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { notificationsService } from "@/services/notifications.service";

export default function NotificationsPage() {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [userId, setUserId] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSend() {
    if (!title.trim() || !body.trim()) {
      toast.error("Title and message are required");
      return;
    }

    setLoading(true);
    try {
      const result = await notificationsService.send({
        title: title.trim(),
        body: body.trim(),
        ...(userId.trim() ? { userId: userId.trim() } : {}),
      });

      toast.success(
        `Notification sent — ${result?.sent ?? 0} delivered, ${result?.failed ?? 0} failed`
      );
      setTitle("");
      setBody("");
      setUserId("");
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data
          ?.message ?? "Failed to send notification";
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-4">
      <PageHeader
        title="Notifications"
        description="Send push notifications to all users or a specific user."
      />

      <Card className="space-y-3 p-4">
        <div className="space-y-1">
          <label className="text-sm font-medium text-foreground">Title</label>
          <Input
            placeholder="Notification title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        </div>

        <div className="space-y-1">
          <label className="text-sm font-medium text-foreground">Message</label>
          <textarea
            className="focus-ring min-h-[120px] w-full rounded-xl border border-border-soft bg-white/60 p-3 text-sm dark:bg-slate-900/45"
            placeholder="Notification message"
            value={body}
            onChange={(e) => setBody(e.target.value)}
          />
        </div>

        <div className="space-y-1">
          <label className="text-sm font-medium text-foreground">
            Target User ID{" "}
            <span className="font-normal text-muted-foreground">
              (leave blank to send to all users)
            </span>
          </label>
          <Input
            placeholder="User UUID — optional"
            value={userId}
            onChange={(e) => setUserId(e.target.value)}
          />
        </div>

        <div className="flex items-center gap-3">
          <Button onClick={handleSend} disabled={loading}>
            {loading ? "Sending…" : userId.trim() ? "Send to User" : "Send to All Users"}
          </Button>
          {!userId.trim() && (
            <p className="text-xs text-muted-foreground">
              Will be delivered to all users with the app installed.
            </p>
          )}
        </div>
      </Card>
    </div>
  );
}
