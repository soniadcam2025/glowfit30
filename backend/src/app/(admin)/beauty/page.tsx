"use client";

import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function BeautyPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Beauty Content" description="Publish and update beauty posts with image links and text." />
      <Card className="space-y-3">
        <Input placeholder="Post title" />
        <Input placeholder="Image URL" />
        <textarea
          className="focus-ring min-h-[130px] w-full rounded-xl border border-border-soft bg-white/60 p-3 text-sm dark:bg-slate-900/45"
          placeholder="Post body"
        />
        <Button onClick={() => toast.success("Beauty content saved")}>Save Post</Button>
      </Card>
    </div>
  );
}
