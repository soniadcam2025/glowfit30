export function PageHeader({ title, description }: { title: string; description?: string }) {
  return (
    <header>
      <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-100">{title}</h1>
      {description ? <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">{description}</p> : null}
    </header>
  );
}
