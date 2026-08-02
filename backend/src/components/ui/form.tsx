"use client";

import * as React from "react";
import {
  Controller,
  FormProvider,
  useFormContext,
  type ControllerProps,
  type FieldPath,
  type FieldValues,
} from "react-hook-form";
import { cn } from "@/lib/utils";

/**
 * Thin React Hook Form bindings.
 *
 * The point is that a field wires up its own label/description/error ids, so
 * validation messages are announced to screen readers and `aria-invalid` is set
 * automatically — the Input component already styles off that. Without this,
 * every form re-implements error display and most forget the ARIA wiring.
 */

export const Form = FormProvider;

type FormFieldContextValue = { name: string };
const FormFieldContext = React.createContext<FormFieldContextValue>({ name: "" });
const FormItemContext = React.createContext<{ id: string }>({ id: "" });

export function FormField<
  TFieldValues extends FieldValues = FieldValues,
  TName extends FieldPath<TFieldValues> = FieldPath<TFieldValues>,
>({ ...props }: ControllerProps<TFieldValues, TName>) {
  return (
    <FormFieldContext.Provider value={{ name: props.name }}>
      <Controller {...props} />
    </FormFieldContext.Provider>
  );
}

export function useFormField() {
  const fieldContext = React.useContext(FormFieldContext);
  const itemContext = React.useContext(FormItemContext);
  const { getFieldState, formState } = useFormContext();
  const fieldState = getFieldState(fieldContext.name, formState);

  const id = itemContext.id;
  return {
    id,
    name: fieldContext.name,
    formItemId: `${id}-item`,
    formDescriptionId: `${id}-description`,
    formMessageId: `${id}-message`,
    ...fieldState,
  };
}

export function FormItem({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  const id = React.useId();
  return (
    <FormItemContext.Provider value={{ id }}>
      <div className={cn("space-y-1.5", className)} {...props} />
    </FormItemContext.Provider>
  );
}

export function FormLabel({ className, ...props }: React.LabelHTMLAttributes<HTMLLabelElement>) {
  const { error, formItemId } = useFormField();
  return (
    <label
      htmlFor={formItemId}
      className={cn(
        "text-xs font-semibold",
        error ? "text-danger" : "text-muted-foreground",
        className,
      )}
      {...props}
    />
  );
}

/** Clones the child control with the ids and aria attributes it needs. */
export function FormControl({ children }: { children: React.ReactElement }) {
  const { error, formItemId, formDescriptionId, formMessageId } = useFormField();
  return React.cloneElement(children, {
    id: formItemId,
    "aria-invalid": !!error,
    "aria-describedby": error
      ? `${formDescriptionId} ${formMessageId}`
      : formDescriptionId,
  } as Partial<React.HTMLAttributes<HTMLElement>>);
}

export function FormDescription({
  className,
  ...props
}: React.HTMLAttributes<HTMLParagraphElement>) {
  const { formDescriptionId } = useFormField();
  return (
    <p
      id={formDescriptionId}
      className={cn("text-xs text-muted-foreground", className)}
      {...props}
    />
  );
}

export function FormMessage({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLParagraphElement>) {
  const { error, formMessageId } = useFormField();
  const body = error ? String(error.message ?? "") : children;
  if (!body) return null;

  return (
    <p
      id={formMessageId}
      // `alert` so the message is announced as soon as it appears.
      role="alert"
      className={cn("text-xs font-medium text-danger", className)}
      {...props}
    >
      {body}
    </p>
  );
}
