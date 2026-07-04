---
name: cloudinary-upload
description: Upload plików na Cloudinary (unsigned preset) — obrazy, pliki raw (Excel, PDF), drag & drop, stany postępu. Bez kodu serwerowego. Używaj przy dodawaniu uploadu plików do aplikacji React.
---

# Cloudinary Upload Pattern

This skill provides file upload functionality using Cloudinary's unsigned upload with drag & drop support.

## When to Use

- Need file hosting without own server
- Uploading images, Excel files, PDFs, or other documents
- Adding drag & drop file upload to forms
- Storing files for later processing (e.g., n8n workflows)

## Triggers

- "dodaj upload plików"
- "upload na Cloudinary"
- "drag and drop upload"
- "hosting plików"

## Prerequisites

### Cloudinary Setup

1. Create free account at [cloudinary.com](https://cloudinary.com)
2. Go to Settings > Upload > Upload presets
3. Create new **unsigned** preset:
   - Preset name: e.g., `my_uploads`
   - Signing Mode: **Unsigned**
   - Folder: optional (e.g., `user_uploads`)
4. Note your **Cloud name** from Dashboard

## Implementation

### 1. Upload Function

```typescript
// services/uploadService.ts

interface CloudinaryResponse {
  secure_url: string;
  public_id: string;
  original_filename: string;
  format: string;
  bytes: number;
}

/**
 * Upload file to Cloudinary
 * @param file - File to upload
 * @param cloudName - Your Cloudinary cloud name
 * @param uploadPreset - Unsigned upload preset name
 * @param resourceType - 'image' | 'raw' | 'video' | 'auto'
 */
export async function uploadToCloudinary(
  file: File,
  cloudName: string,
  uploadPreset: string,
  resourceType: 'image' | 'raw' | 'video' | 'auto' = 'auto'
): Promise<string> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', uploadPreset);

  // Use 'raw' for non-image files (Excel, PDF, etc.)
  // Use 'image' for images
  // Use 'auto' to let Cloudinary detect
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`,
    {
      method: 'POST',
      body: formData
    }
  );

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.error?.message || 'Upload failed');
  }

  const data: CloudinaryResponse = await response.json();

  if (!data.secure_url) {
    throw new Error('Failed to get file URL');
  }

  return data.secure_url;
}
```

### 2. Usage Examples

#### Simple Upload

```typescript
const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0];
  if (!file) return;

  try {
    const url = await uploadToCloudinary(
      file,
      'your_cloud_name',
      'your_upload_preset',
      'raw' // for Excel, PDF, etc.
    );
    console.log('Uploaded:', url);
  } catch (error) {
    console.error('Upload failed:', error);
  }
};
```

#### Upload with Progress State

```typescript
const [uploadState, setUploadState] = useState<{
  status: 'idle' | 'uploading' | 'success' | 'error';
  progress?: string;
  url?: string;
}>({ status: 'idle' });

const handleUpload = async (file: File) => {
  setUploadState({ status: 'uploading', progress: 'Uploading...' });

  try {
    const url = await uploadToCloudinary(file, 'cloud_name', 'preset', 'raw');
    setUploadState({ status: 'success', url });
  } catch (error) {
    setUploadState({
      status: 'error',
      progress: error instanceof Error ? error.message : 'Upload failed'
    });
  }
};
```

### 3. Drag & Drop Component

```typescript
import React, { useState, useRef, DragEvent, ChangeEvent } from 'react';
import { Upload, Check, AlertCircle, Loader2, FileSpreadsheet } from 'lucide-react';

interface FileUploadProps {
  onUpload: (url: string) => void;
  accept?: string;
  cloudName: string;
  uploadPreset: string;
}

export function FileUpload({ onUpload, accept = '.xlsx,.xls', cloudName, uploadPreset }: FileUploadProps) {
  const [isDragOver, setIsDragOver] = useState(false);
  const [uploadState, setUploadState] = useState<'idle' | 'uploading' | 'success' | 'error'>('idle');
  const [fileName, setFileName] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFile = async (file: File) => {
    // Validate file extension
    const allowedExtensions = accept.split(',').map(ext => ext.trim().toLowerCase());
    const fileExtension = file.name.toLowerCase().slice(file.name.lastIndexOf('.'));

    if (!allowedExtensions.includes(fileExtension)) {
      alert(`Allowed formats: ${accept}`);
      return;
    }

    setFileName(file.name);
    setUploadState('uploading');

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('upload_preset', uploadPreset);

      const response = await fetch(
        `https://api.cloudinary.com/v1_1/${cloudName}/raw/upload`,
        { method: 'POST', body: formData }
      );

      if (!response.ok) {
        throw new Error('Upload failed');
      }

      const data = await response.json();
      setUploadState('success');
      onUpload(data.secure_url);
    } catch (error) {
      setUploadState('error');
      console.error('Upload error:', error);
    }
  };

  const handleDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragOver(false);

    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  };

  const handleDragOver = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragOver(false);
  };

  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
  };

  return (
    <div
      onClick={() => inputRef.current?.click()}
      onDrop={handleDrop}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      className={`
        relative border-2 border-dashed rounded-lg p-6 text-center cursor-pointer
        transition-all duration-200
        ${isDragOver
          ? 'border-blue-500 bg-blue-50'
          : uploadState === 'success'
            ? 'border-emerald-500 bg-emerald-50'
            : uploadState === 'error'
              ? 'border-rose-500 bg-rose-50'
              : 'border-slate-300 hover:border-slate-400 hover:bg-slate-50'
        }
      `}
    >
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        onChange={handleInputChange}
        className="hidden"
      />

      <div className="flex flex-col items-center gap-2">
        {uploadState === 'uploading' ? (
          <>
            <Loader2 className="w-8 h-8 text-blue-500 animate-spin" />
            <p className="text-sm text-slate-600">Uploading {fileName}...</p>
          </>
        ) : uploadState === 'success' ? (
          <>
            <Check className="w-8 h-8 text-emerald-500" />
            <p className="text-sm text-emerald-700">{fileName}</p>
            <p className="text-xs text-slate-500">Click to upload another file</p>
          </>
        ) : uploadState === 'error' ? (
          <>
            <AlertCircle className="w-8 h-8 text-rose-500" />
            <p className="text-sm text-rose-700">Upload failed</p>
            <p className="text-xs text-slate-500">Click to try again</p>
          </>
        ) : (
          <>
            <FileSpreadsheet className="w-8 h-8 text-slate-400" />
            <p className="text-sm text-slate-600">
              <span className="font-medium text-blue-600">Click to upload</span> or drag and drop
            </p>
            <p className="text-xs text-slate-500">
              Allowed: {accept}
            </p>
          </>
        )}
      </div>
    </div>
  );
}
```

### 4. Usage in Form

```typescript
function MyForm() {
  const [fileUrl, setFileUrl] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (!fileUrl) {
      alert('Please upload a file first');
      return;
    }

    // Use fileUrl in your form submission
    await api.createRecord({
      file: fileUrl,
      // ... other fields
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <FileUpload
        cloudName="your_cloud_name"
        uploadPreset="your_preset"
        accept=".xlsx,.xls,.pdf"
        onUpload={(url) => setFileUrl(url)}
      />

      {fileUrl && (
        <p className="text-sm text-emerald-600">
          File uploaded: <a href={fileUrl} target="_blank">{fileUrl}</a>
        </p>
      )}

      <button type="submit">Submit</button>
    </form>
  );
}
```

## Resource Types

| Type | Endpoint | Use for |
|------|----------|---------|
| `image` | `/image/upload` | Images (JPG, PNG, GIF, WebP) |
| `raw` | `/raw/upload` | Documents (Excel, PDF, CSV, etc.) |
| `video` | `/video/upload` | Videos (MP4, MOV, etc.) |
| `auto` | `/auto/upload` | Let Cloudinary detect |

## Airtable Integration

Store Cloudinary URLs in Airtable attachment fields:

```typescript
// After upload, save to Airtable
const fileUrl = await uploadToCloudinary(file, cloudName, preset, 'raw');

await airtable.createRecord('My Table', {
  'Name': 'Product XYZ',
  'File': [{ url: fileUrl, filename: file.name }]
});
```

## Environment Variables

```bash
# Optional - can also be hardcoded or passed as props
VITE_CLOUDINARY_CLOUD_NAME=your_cloud_name
VITE_CLOUDINARY_UPLOAD_PRESET=your_preset
```

## Security Notes

1. **Unsigned uploads are public** - Anyone can upload to your account with the preset
2. **Set upload restrictions** in Cloudinary preset:
   - Allowed formats (e.g., only xlsx, pdf)
   - Max file size
   - Folder prefix
3. **Consider signed uploads** for sensitive applications (requires server)

## Best Practices

1. **Validate client-side** - Check file type/size before upload
2. **Show progress** - Indicate upload state to users
3. **Handle errors gracefully** - Show meaningful error messages
4. **Use appropriate resource type** - `raw` for documents, `image` for images
5. **Set folder in preset** - Organize uploads in Cloudinary

## Pułapki

### 1. Unsigned preset nie istnieje lub jest "signed"

Cloudinary zwraca `401` lub `Upload preset must be whitelisted` — ale komunikat nie mówi wprost, że preset jest ustawiony na "signed". Claude często generuje kod z nazwą presetu, której użytkownik nie utworzył w dashboardzie.

**Rozwiązanie**: Zawsze instruuj użytkownika, żeby sprawdził w Cloudinary Dashboard → Settings → Upload → Upload presets, że preset istnieje i ma Signing Mode: **Unsigned**.

### 2. `resource_type: "auto"` nie działa dla plików raw

Cloudinary z unsigned presetem często odrzuca pliki Excel/CSV/PDF przy `auto` — zwraca `Invalid image file`. Claude domyślnie daje `auto`, bo wydaje się bezpieczne.

```
❌ fetch(`https://api.cloudinary.com/v1_1/${cloud}/auto/upload`, ...)
   // Excel → "Invalid image file"

✅ fetch(`https://api.cloudinary.com/v1_1/${cloud}/raw/upload`, ...)
   // Excel → działa poprawnie
```

### 3. Brak walidacji rozmiaru pliku po stronie klienta

Cloudinary na darmowym planie odrzuca pliki >10 MB dopiero PO przesłaniu całości. Użytkownik czeka na upload, a potem dostaje błąd. Claude prawie nigdy nie dodaje walidacji rozmiaru przed uploadem.

```typescript
// ✅ Dodaj walidację PRZED uploadem
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
if (file.size > MAX_FILE_SIZE) {
  setError('Plik jest za duży (max 10 MB)');
  return;
}
```

### 4. CORS błędy przez literówkę w `cloud_name`

Gdy `cloud_name` jest niepoprawny, Cloudinary zwraca redirect na stronę 404, a przeglądarka raportuje to jako CORS error — nie jako 404. Claude (i użytkownik) szukają problemu w konfiguracji CORS zamiast sprawdzić nazwę clouda.

**Rozwiązanie**: Przy błędzie CORS — najpierw zweryfikuj `cloud_name` otwierając `https://res.cloudinary.com/<cloud_name>/image/upload/sample.jpg` w przeglądarce.

### 5. Progress bar pokazuje % wysłanych danych, nie % przetworzenia

Przy użyciu `XMLHttpRequest` z `upload.onprogress`, pasek dochodzi do 100% gdy dane dotrą do serwera — ale Cloudinary jeszcze przetwarza plik. Użytkownik widzi 100% i myśli, że upload się zawiesił.

```typescript
// ❌ Po 100% progressu od razu ustawiasz "success"
xhr.upload.onprogress = (e) => setProgress(e.loaded / e.total * 100);

// ✅ Po 100% progressu pokaż "Przetwarzanie..." i czekaj na response
xhr.upload.onprogress = (e) => setProgress(e.loaded / e.total * 100);
xhr.onload = () => setStatus('success'); // dopiero tu jest NAPRAWDĘ gotowe
```

### 6. Transformacje URL nie działają dla plików `raw`

Claude często generuje URL z transformacjami (np. `/w_300,h_300/`) dla plików uploadowanych jako `raw`. Cloudinary ignoruje transformacje dla raw files — zwraca oryginalny plik, bez błędu.

```
❌ https://res.cloudinary.com/demo/raw/upload/w_300/plik.pdf
   // Transformacja zignorowana — zwraca oryginalny PDF

✅ Transformacje działają TYLKO dla resource_type: "image" i "video"
```

### 7. Drag & drop nie resetuje stanu po kolejnym uplaodzie

Claude generuje komponent, który po sukcesie pokazuje "Uploaded!" — ale przy dropnięciu kolejnego pliku stan `success` nie wraca do `uploading`. Użytkownik dropuje nowy plik, a UI nadal pokazuje stary.

```typescript
// ✅ Resetuj stan NA POCZĄTKU handleFile
const handleFile = async (file: File) => {
  setUploadState('uploading');  // reset PRZED walidacją
  setFileName(file.name);
  // ...reszta logiki
};
```

## Dependencies

- **Icons**: Lucide React (or any icon library)
- **Styling**: Tailwind CSS

No npm packages needed - uses native `fetch` API.
