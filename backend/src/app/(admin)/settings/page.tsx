"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";
import { withRoleGuard } from "@/components/auth/with-role-guard";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { legalService } from "@/services/legal.service";

function apiMessage(err: unknown, fallback: string) {
  return (
    (err as { response?: { data?: { message?: string } } })?.response?.data
      ?.message ?? fallback
  );
}

function LegalContentCard() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [title, setTitle] = useState("Privacy Policy & Terms");
  const [content, setContent] = useState("");

  useEffect(() => {
    legalService
      .get()
      .then((doc) => {
        setTitle(doc.title);
        setContent(doc.content);
      })
      .catch((err) => toast.error(apiMessage(err, "Failed to load legal content")))
      .finally(() => setLoading(false));
  }, []);

  async function handleSave() {
    if (!content.trim()) {
      toast.error("Content is required");
      return;
    }
    setSaving(true);
    try {
      const doc = await legalService.update({ title: title.trim(), content: content.trim() });
      setTitle(doc.title);
      setContent(doc.content);
      toast.success("Legal content updated — synced to the Flutter app.");
    } catch (err) {
      toast.error(apiMessage(err, "Failed to update legal content"));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card className="space-y-3 p-4">
      <div>
        <h3 className="text-sm font-semibold text-foreground">Legal Content</h3>
        <p className="text-xs text-muted-foreground">
          Shown in the Flutter app under Profile → App Settings → Privacy Policy & Terms.
        </p>
      </div>
      {loading ? (
        <p className="text-sm text-muted-foreground">Loading…</p>
      ) : (
        <>
          <div className="space-y-1">
            <label className="text-sm font-medium text-foreground">Title</label>
            <Input value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-foreground">Content</label>
            <textarea
              className="focus-ring min-h-[220px] w-full rounded-xl border border-border-soft bg-white/60 p-3 text-sm dark:bg-slate-900/45"
              value={content}
              onChange={(e) => setContent(e.target.value)}
            />
          </div>
          <Button onClick={handleSave} disabled={saving}>
            {saving ? "Saving…" : "Save Legal Content"}
          </Button>
        </>
      )}
    </Card>
  );
}

function SettingsPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Settings" description="Manage app config and admin profile settings." />
      <Card className="space-y-3 p-4">
        <h3 className="text-sm font-semibold text-foreground">General</h3>
        <Input placeholder="App name" defaultValue="GlowFit" />
        <Input placeholder="Admin display name" defaultValue="GlowFit Admin" />
        <Input placeholder="Support email" defaultValue="support@glowfit.com" />
        <Button onClick={() => toast.success("Settings updated")}>Save Settings</Button>
      </Card>
      <LegalContentCard />
    </div>
  );
}

export default withRoleGuard(SettingsPage, ["super_admin"]);
