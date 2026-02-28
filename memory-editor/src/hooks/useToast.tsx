import * as React from "react";
import * as ToastPrimitive from "@radix-ui/react-toast";
import { Toast, ToastTitle, ToastDescription, ToastClose } from "@/components/ui/toast";

export type ToastProps = {
  title?: string;
  description?: string;
  variant?: "default" | "destructive";
};

const ToastContext = React.createContext<{
  toast: (props: ToastProps) => void;
}>({ toast: () => {} });

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = React.useState<Array<ToastProps & { id: number }>>([]);
  const idRef = React.useRef(0);

  const toast = React.useCallback((props: ToastProps) => {
    const id = ++idRef.current;
    setToasts((t) => [...t, { ...props, id }]);
  }, []);

  return (
    <ToastContext.Provider value={{ toast }}>
      <ToastPrimitive.Provider>
        {children}
        {toasts.map((t) => (
          <Toast
            key={t.id}
            variant={t.variant}
            onOpenChange={(open) => {
              if (!open) setToasts((prev) => prev.filter((x) => x.id !== t.id));
            }}
          >
            {t.title && <ToastTitle>{t.title}</ToastTitle>}
            {t.description && <ToastDescription>{t.description}</ToastDescription>}
            <ToastClose />
          </Toast>
        ))}
        <ToastPrimitive.Viewport className="fixed top-0 right-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4 sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[420px]" />
      </ToastPrimitive.Provider>
    </ToastContext.Provider>
  );
}

export function useToast() {
  return React.useContext(ToastContext);
}

export function Toaster() {
  return null;
}
