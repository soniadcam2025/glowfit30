export default function DesktopOnlyPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-6 dark:bg-slate-950">
      <div className="max-w-sm text-center">
        <div className="mb-4 text-4xl">🖥️</div>
        <p className="text-base font-medium text-slate-700 dark:text-slate-200">
          Sorry, The page you want to view can only be accessible from desktop
        </p>
      </div>
    </div>
  );
}
