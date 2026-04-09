"use client";

import { toast } from "sonner";
import { withRoleGuard } from "@/components/auth/with-role-guard";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

function SettingsPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Settings" description="Manage app config and admin profile settings." />
      <Card className="space-y-3">
        <Input placeholder="App name" defaultValue="GlowFit" />
        <Input placeholder="Admin display name" defaultValue="GlowFit Admin" />
        <Input placeholder="Support email" defaultValue="support@glowfit.com" />
        <Button onClick={() => toast.success("Settings updated")}>Save Settings</Button>
      </Card>
    </div>
  );
}

export default withRoleGuard(SettingsPage, ["super_admin"]);
