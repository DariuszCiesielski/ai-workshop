---
name: react-query-hooks
description: Custom hooki React z TanStack Query (React Query) — pobieranie danych, mutacje, cache. Wzorce CRUD, optimistic updates, auto-refresh. Używaj przy implementacji data fetching w aplikacjach React.
---

# React Query Hooks Pattern

This skill provides patterns for creating custom hooks with TanStack Query (React Query) for efficient data fetching and state management.

## When to Use

- Implementing data fetching in React applications
- Creating CRUD hooks for API operations
- Setting up automatic cache invalidation
- Implementing optimistic updates
- Adding auto-refresh functionality

## Setup

### Installation

```bash
npm install @tanstack/react-query
```

### Provider Setup

```typescript
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  );
}
```

## Hook Patterns

### 1. Basic Fetch Hook

```typescript
// hooks/useUsers.ts
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

interface User {
  id: string;
  email: string;
  full_name: string | null;
  created_at: string;
}

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: async (): Promise<User[]> => {
      const { data, error } = await supabase
        .from('users_view')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data as User[];
    },
  });
}
```

### 2. CRUD Hook with Mutations

```typescript
// hooks/useApplications.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

interface Application {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  url: string | null;
  is_active: boolean;
  created_at: string;
}

interface CreateApplicationInput {
  name: string;
  slug: string;
  description?: string;
  url?: string;
}

export function useApplications() {
  const queryClient = useQueryClient();

  // Fetch all applications
  const query = useQuery({
    queryKey: ['applications'],
    queryFn: async (): Promise<Application[]> => {
      const { data, error } = await supabase
        .from('applications')
        .select('*')
        .order('name');

      if (error) throw error;
      return data as Application[];
    },
  });

  // Create application
  const createMutation = useMutation({
    mutationFn: async (input: CreateApplicationInput) => {
      const { data, error } = await supabase
        .from('applications')
        .insert(input)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['applications'] });
    },
  });

  // Update application
  const updateMutation = useMutation({
    mutationFn: async ({ id, ...updates }: Partial<Application> & { id: string }) => {
      const { data, error } = await supabase
        .from('applications')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['applications'] });
    },
  });

  // Delete application
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('applications')
        .delete()
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['applications'] });
    },
  });

  // Toggle active status
  const toggleActiveMutation = useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { error } = await supabase
        .from('applications')
        .update({ is_active })
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['applications'] });
    },
  });

  return {
    // Query
    applications: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,

    // Mutations
    createApplication: createMutation.mutateAsync,
    updateApplication: updateMutation.mutateAsync,
    deleteApplication: deleteMutation.mutateAsync,
    toggleActive: toggleActiveMutation.mutateAsync,

    // Mutation states
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  };
}
```

### 3. Hook with Auto-Refresh

```typescript
// hooks/useDashboardStats.ts
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

interface DashboardStats {
  totalUsers: number;
  totalApplications: number;
  totalActiveAccess: number;
  totalAdmins: number;
}

export function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async (): Promise<DashboardStats> => {
      const [users, apps, access, admins] = await Promise.all([
        supabase.from('users_view').select('id', { count: 'exact', head: true }),
        supabase.from('applications').select('id', { count: 'exact', head: true }),
        supabase.from('user_app_access').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('admins').select('id', { count: 'exact', head: true }),
      ]);

      return {
        totalUsers: users.count ?? 0,
        totalApplications: apps.count ?? 0,
        totalActiveAccess: access.count ?? 0,
        totalAdmins: admins.count ?? 0,
      };
    },
    refetchInterval: 30000, // Auto-refresh every 30 seconds
    staleTime: 10000, // Consider data stale after 10 seconds
  });
}
```

### 4. Hook with Dependent Query

```typescript
// hooks/useUserApplications.ts
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

interface UserApplication {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  url: string | null;
  granted_at: string;
}

export function useUserApplications() {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['user-applications', user?.id],
    queryFn: async (): Promise<UserApplication[]> => {
      if (!user) return [];

      const { data, error } = await supabase
        .from('user_app_access')
        .select(`
          granted_at,
          applications (
            id,
            name,
            slug,
            description,
            url
          )
        `)
        .eq('user_id', user.id)
        .eq('is_active', true);

      if (error) throw error;

      return data.map(item => ({
        ...item.applications,
        granted_at: item.granted_at,
      })) as UserApplication[];
    },
    enabled: !!user, // Only run when user is available
  });
}
```

### 5. Hook with Optimistic Updates

```typescript
// hooks/usePermissions.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

interface Permission {
  id: string;
  user_id: string;
  application_id: string;
  is_active: boolean;
}

export function usePermissions() {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['permissions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('user_app_access')
        .select('*');

      if (error) throw error;
      return data as Permission[];
    },
  });

  const togglePermission = useMutation({
    mutationFn: async ({ userId, appId, grant }: { userId: string; appId: string; grant: boolean }) => {
      if (grant) {
        const { error } = await supabase
          .from('user_app_access')
          .upsert({
            user_id: userId,
            application_id: appId,
            is_active: true,
          });
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('user_app_access')
          .delete()
          .eq('user_id', userId)
          .eq('application_id', appId);
        if (error) throw error;
      }
    },
    // Optimistic update
    onMutate: async ({ userId, appId, grant }) => {
      await queryClient.cancelQueries({ queryKey: ['permissions'] });

      const previousPermissions = queryClient.getQueryData(['permissions']);

      queryClient.setQueryData(['permissions'], (old: Permission[] | undefined) => {
        if (!old) return old;

        if (grant) {
          return [...old, { user_id: userId, application_id: appId, is_active: true }];
        } else {
          return old.filter(p => !(p.user_id === userId && p.application_id === appId));
        }
      });

      return { previousPermissions };
    },
    onError: (_err, _variables, context) => {
      // Rollback on error
      queryClient.setQueryData(['permissions'], context?.previousPermissions);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['permissions'] });
    },
  });

  return {
    permissions: query.data ?? [],
    isLoading: query.isLoading,
    togglePermission: togglePermission.mutateAsync,
    isToggling: togglePermission.isPending,
  };
}
```

## Usage in Components

```typescript
// pages/Applications.tsx
import { useApplications } from '@/hooks/useApplications';

function ApplicationsPage() {
  const {
    applications,
    isLoading,
    error,
    createApplication,
    deleteApplication,
    isCreating,
  } = useApplications();

  if (isLoading) return <Skeleton />;
  if (error) return <Error message={error.message} />;

  const handleCreate = async (data: CreateApplicationInput) => {
    try {
      await createApplication(data);
      toast.success('Aplikacja utworzona');
    } catch (err) {
      toast.error('Błąd podczas tworzenia');
    }
  };

  return (
    <div>
      {applications.map(app => (
        <ApplicationCard
          key={app.id}
          app={app}
          onDelete={() => deleteApplication(app.id)}
        />
      ))}
    </div>
  );
}
```

## Best Practices

1. **Use queryKey arrays** - Include all variables that affect the query
2. **Invalidate related queries** - After mutations, invalidate all affected queries
3. **Handle loading and error states** - Always show appropriate UI feedback
4. **Use staleTime wisely** - Set appropriate staleness for your data
5. **Enable only when ready** - Use `enabled` option for dependent queries
6. **Implement optimistic updates** - For better UX on simple mutations
7. **Clear cache on logout** - Use `queryClient.clear()` when user signs out

### 6. Hook with Progress State (Upload Pattern)

For operations with multiple stages (validation → processing → completion):

```typescript
// hooks/useUploadDocument.ts
import { useState, useCallback } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';

type UploadStage = 'idle' | 'validating' | 'uploading' | 'completed' | 'error';

interface UploadProgress {
  stage: UploadStage;
  progress: number; // 0-100
  message: string;
}

interface UploadResult {
  success: boolean;
  documentId?: string;
  error?: string;
}

const ALLOWED_EXTENSIONS = ['.pdf', '.txt', '.doc', '.docx'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

const validateFile = (file: File): { valid: boolean; error?: string } => {
  const ext = file.name.slice(file.name.lastIndexOf('.')).toLowerCase();
  if (!ALLOWED_EXTENSIONS.includes(ext)) {
    return { valid: false, error: `Nieobsługiwany format. Dozwolone: ${ALLOWED_EXTENSIONS.join(', ')}` };
  }
  if (file.size > MAX_FILE_SIZE) {
    return { valid: false, error: `Plik jest za duży. Maksymalny rozmiar: ${MAX_FILE_SIZE / 1024 / 1024}MB` };
  }
  if (file.size === 0) {
    return { valid: false, error: 'Plik jest pusty' };
  }
  return { valid: true };
};

export function useUploadDocument() {
  const queryClient = useQueryClient();
  const [progress, setProgress] = useState<UploadProgress | null>(null);

  const uploadMutation = useMutation({
    mutationFn: async (file: File): Promise<UploadResult> => {
      // Stage 1: Validation
      setProgress({ stage: 'validating', progress: 10, message: 'Sprawdzanie pliku...' });
      const validation = validateFile(file);
      if (!validation.valid) {
        throw new Error(validation.error);
      }

      // Stage 2: Upload
      setProgress({ stage: 'uploading', progress: 50, message: 'Wysyłanie pliku...' });

      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Błąd podczas wysyłania');
      }

      const result = await response.json();

      // Stage 3: Success
      setProgress({ stage: 'completed', progress: 100, message: 'Plik został przesłany' });

      return { success: true, documentId: result.id };
    },
    onSuccess: () => {
      // Invalidate related queries
      queryClient.invalidateQueries({ queryKey: ['documents'] });
    },
    onError: (error: Error) => {
      setProgress({ stage: 'error', progress: 0, message: error.message });
    },
  });

  const resetProgress = useCallback(() => {
    setProgress(null);
    uploadMutation.reset();
  }, [uploadMutation]);

  return {
    upload: uploadMutation.mutate,
    uploadAsync: uploadMutation.mutateAsync,
    isUploading: uploadMutation.isPending,
    progress,
    resetProgress,
    error: uploadMutation.error,
    isCompleted: progress?.stage === 'completed',
    isError: progress?.stage === 'error',
  };
}
```

**Usage in component:**

```typescript
function UploadDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const { upload, isUploading, progress, resetProgress, isCompleted, isError } = useUploadDocument();
  const [file, setFile] = useState<File | null>(null);

  const handleSubmit = () => {
    if (file) {
      upload(file);
    }
  };

  const handleClose = () => {
    resetProgress();
    setFile(null);
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent>
        {/* File input */}
        <input
          type="file"
          onChange={(e) => setFile(e.target.files?.[0] || null)}
          disabled={isUploading}
        />

        {/* Progress bar */}
        {progress && (
          <div className="space-y-2">
            <Progress value={progress.progress} />
            <p className="text-sm text-muted-foreground">{progress.message}</p>
          </div>
        )}

        {/* Status icons */}
        {isCompleted && <CheckCircle className="text-green-500" />}
        {isError && <AlertCircle className="text-red-500" />}

        {/* Actions */}
        <Button onClick={handleSubmit} disabled={!file || isUploading}>
          {isUploading ? 'Wysyłanie...' : 'Wyślij'}
        </Button>
      </DialogContent>
    </Dialog>
  );
}
```

### 7. Hook with URL Validation

```typescript
// hooks/useAddUrl.ts
import { useState, useCallback } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';

const validateUrl = (url: string): { valid: boolean; error?: string } => {
  const trimmedUrl = url.trim();
  if (!trimmedUrl) {
    return { valid: false, error: 'URL jest wymagany' };
  }
  try {
    const urlObj = new URL(trimmedUrl);
    if (!['http:', 'https:'].includes(urlObj.protocol)) {
      return { valid: false, error: 'URL musi zaczynać się od http:// lub https://' };
    }
  } catch {
    return { valid: false, error: 'Nieprawidłowy format adresu URL' };
  }
  return { valid: true };
};

export function useAddUrl() {
  const queryClient = useQueryClient();
  const [progress, setProgress] = useState<{ stage: string; message: string } | null>(null);

  const addUrlMutation = useMutation({
    mutationFn: async (url: string) => {
      setProgress({ stage: 'validating', message: 'Weryfikacja URL...' });
      const validation = validateUrl(url);
      if (!validation.valid) {
        throw new Error(validation.error);
      }

      setProgress({ stage: 'adding', message: 'Dodawanie URL...' });
      const response = await fetch('/api/urls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: url.trim() }),
      });

      if (!response.ok) {
        throw new Error('Błąd podczas dodawania URL');
      }

      setProgress({ stage: 'completed', message: 'URL został dodany' });
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['documents'] });
    },
    onError: (error: Error) => {
      setProgress({ stage: 'error', message: error.message });
    },
  });

  const resetProgress = useCallback(() => {
    setProgress(null);
    addUrlMutation.reset();
  }, [addUrlMutation]);

  return {
    addUrl: addUrlMutation.mutate,
    addUrlAsync: addUrlMutation.mutateAsync,
    isAdding: addUrlMutation.isPending,
    progress,
    resetProgress,
    error: addUrlMutation.error,
  };
}
```

## Cache Invalidation on Logout

```typescript
// contexts/AuthContext.tsx
import { useQueryClient } from '@tanstack/react-query';

const signOut = async () => {
  const queryClient = useQueryClient();
  await supabase.auth.signOut();
  queryClient.clear(); // Clear all cached data
};
```

## Query Keys Convention

Use consistent, hierarchical query keys:

```typescript
// Good patterns:
queryKey: ['documents']                    // All documents
queryKey: ['documents', agentId]           // Documents for specific agent
queryKey: ['documents', { type: 'pdf' }]   // Filtered documents
queryKey: ['document', documentId]         // Single document
queryKey: ['documentStats', agentId]       // Stats for agent

// Related invalidation:
queryClient.invalidateQueries({ queryKey: ['documents'] }); // Invalidates all document queries
queryClient.invalidateQueries({ queryKey: ['documents', agentId] }); // Specific agent only
```

## Pułapki

### 1. Brak invalidateQueries po mutacji
**Problem:** Zapominasz o `invalidateQueries()` w `onSuccess` — lista pokazuje nieaktualne dane przez cały `staleTime`.
**Rozwiązanie:** ZAWSZE dodaj `onSuccess: () => queryClient.invalidateQueries({ queryKey: [...] })` w każdej mutacji.

### 2. staleTime: 0 powoduje refetch po każdej nawigacji
**Problem:** Domyślny `staleTime: 0` oznacza, że dane są „stale" natychmiast — każde przejście między stronami triggeruje nowy request.
**Rozwiązanie:** Ustaw rozsądny `staleTime` (np. `5 * 60 * 1000` dla danych, `30 * 1000` dla statystyk).

### 3. Brak enabled na zależnym query
**Problem:** Query próbuje fetch bez wymaganego warunku (np. `userId` jest `undefined`) i rzuca błąd lub zwraca puste dane.
**Rozwiązanie:** Zawsze dodaj `enabled: !!userId` na queryach zależnych od kontekstu auth lub parametrów.

### 4. Optimistic update bez rollbacku
**Problem:** W `onMutate` aktualizujesz cache optimistycznie, ale mutacja failuje — UI pokazuje stare dane, cache jest niespójny.
**Rozwiązanie:** Zawsze zapisz `previousData` w `onMutate` i przywróć go w `onError`: `queryClient.setQueryData(key, context?.previousData)`.

### 5. Race condition przy równoczesnych mutacjach
**Problem:** Kilka mutacji invaliduje ten sam query jednocześnie — wielokrotne refetche i nieprzewidywalne wyniki.
**Rozwiązanie:** Użyj `onSettled` zamiast `onSuccess` do invalidacji, lub łącz operacje w `Promise.all()`.
