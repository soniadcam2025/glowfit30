import type { UserItem } from "@/types";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

export function UsersTable({
  rows,
  onView,
  onBlock,
}: {
  rows: UserItem[];
  onView: (user: UserItem) => void;
  onBlock: (user: UserItem) => void;
}) {
  return (
    <Card className="overflow-auto p-0">
      <table className="w-full min-w-[700px] text-left text-sm">
        <thead>
          <tr className="border-b border-border-soft">
            <th className="px-4 py-3">Name</th>
            <th className="px-4 py-3">Email</th>
            <th className="px-4 py-3">Status</th>
            <th className="px-4 py-3">Joined</th>
            <th className="px-4 py-3">Actions</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((user) => (
            <tr key={user.id} className="border-b border-border-soft/70 last:border-0">
              <td className="px-4 py-3 font-medium">{user.name}</td>
              <td className="px-4 py-3">{user.email}</td>
              <td className="px-4 py-3 capitalize">{user.status}</td>
              <td className="px-4 py-3">{user.joinedAt}</td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <Button variant="ghost" onClick={() => onView(user)}>
                    View
                  </Button>
                  <Button variant="secondary">Edit</Button>
                  <Button variant="danger" onClick={() => onBlock(user)}>
                    Block
                  </Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </Card>
  );
}
