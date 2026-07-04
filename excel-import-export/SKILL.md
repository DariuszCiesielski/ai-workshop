---
name: excel-import-export
description: Import i eksport plików Excel (xlsx-js-style) — parsowanie do JSON, eksport ze stylami (nagłówki, obramowania, kolory), File System Access API, detekcja formatu. Używaj przy dodawaniu funkcji import/eksport Excel do aplikacji React.
---

# Excel Import/Export Pattern

This skill provides Excel file handling using `xlsx-js-style` library with custom styling support.

## When to Use

- Importing data from Excel files uploaded by users
- Exporting data to styled Excel files
- Need formatted headers, colors, borders in exports
- Detecting Excel file format (different column structures)
- Using native file save dialogs (File System Access API)

## Triggers

- "import z Excel"
- "eksport do Excel"
- "parsowanie pliku Excel"
- "xlsx ze stylami"

## Setup

### Installation

```bash
npm install xlsx-js-style
```

### Import

```typescript
import XLSX from 'xlsx-js-style';
```

## Excel Import (Parsing)

### 1. Basic Parser

```typescript
interface ParsedExcelData {
  headers: string[];
  rows: Record<string, string>[];
}

/**
 * Parse Excel file to JSON
 */
async function parseExcelFile(file: File): Promise<ParsedExcelData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      try {
        const data = e.target?.result;
        const workbook = XLSX.read(data, { type: 'binary' });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];

        // Convert to array of arrays (first row = headers)
        const jsonData = XLSX.utils.sheet_to_json<string[]>(worksheet, {
          header: 1,
          defval: ''
        });

        if (jsonData.length === 0) {
          resolve({ headers: [], rows: [] });
          return;
        }

        // First row = headers
        const headers = jsonData[0].map(h => String(h).trim());

        // Remaining rows = data
        const rows: Record<string, string>[] = [];
        for (let i = 1; i < jsonData.length; i++) {
          const row = jsonData[i];
          const rowObj: Record<string, string> = {};
          let hasData = false;

          headers.forEach((header, index) => {
            const value = row[index] !== undefined ? String(row[index]).trim() : '';
            if (value) hasData = true;
            rowObj[header] = value;
          });

          // Skip empty rows
          if (hasData) {
            rows.push(rowObj);
          }
        }

        resolve({ headers, rows });
      } catch (err) {
        reject(err);
      }
    };

    reader.onerror = () => reject(new Error('File read error'));
    reader.readAsBinaryString(file);
  });
}
```

### 2. Format Detection

Detect what type of Excel file was uploaded:

```typescript
type ExcelFormat = 'product-data' | 'url-only' | 'unknown';

const KNOWN_PRODUCT_HEADERS = [
  'Symbol produktu',
  'Nazwa produktu',
  'Kod EAN',
  'Kod producenta',
  'Opis HTML',
  'Kategoria ID'
];

function detectExcelFormat(headers: string[]): ExcelFormat {
  const headersLower = headers.map(h => h.toLowerCase());
  const knownHeadersLower = KNOWN_PRODUCT_HEADERS.map(h => h.toLowerCase());

  // Check if at least 3 known headers are present
  const matchedHeaders = headersLower.filter(h => knownHeadersLower.includes(h));
  if (matchedHeaders.length >= 3) {
    return 'product-data';
  }

  // Single column with URLs
  if (headers.length === 1 ||
      headersLower.some(h => h.includes('url') || h.includes('link'))) {
    return 'url-only';
  }

  return 'unknown';
}
```

### 3. Usage Example

```typescript
const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0];
  if (!file) return;

  try {
    const { headers, rows } = await parseExcelFile(file);
    const format = detectExcelFormat(headers);

    console.log('Format:', format);
    console.log('Headers:', headers);
    console.log('Rows:', rows);

    // Process based on format
    if (format === 'product-data') {
      // Create records with full product data
      for (const row of rows) {
        await createRecord(row);
      }
    } else if (format === 'url-only') {
      // Process URLs
      const urls = rows.map(r => Object.values(r)[0]);
    }
  } catch (error) {
    console.error('Parse error:', error);
  }
};
```

## Excel Export (with Styling)

### 1. Basic Export with Styles

```typescript
interface ExportColumn {
  key: string;
  header: string;
  width: number; // in characters
}

async function exportToExcel(
  data: Record<string, any>[],
  columns: ExportColumn[],
  fileName: string
) {
  // Prepare headers and data rows
  const headers = columns.map(c => c.header);
  const rows = data.map(item =>
    columns.map(col => item[col.key] ?? '')
  );

  // Create worksheet
  const worksheet = XLSX.utils.aoa_to_sheet([headers, ...rows]);

  // Header style
  const headerStyle = {
    font: { bold: true, color: { rgb: 'FFFFFF' }, sz: 11 },
    fill: { fgColor: { rgb: '4F46E5' } }, // Indigo
    alignment: { horizontal: 'center', vertical: 'center' },
    border: {
      top: { style: 'thin', color: { rgb: '000000' } },
      bottom: { style: 'thin', color: { rgb: '000000' } },
      left: { style: 'thin', color: { rgb: '000000' } },
      right: { style: 'thin', color: { rgb: '000000' } }
    }
  };

  // Cell style
  const cellStyle = {
    alignment: { wrapText: true, vertical: 'top' },
    border: {
      top: { style: 'thin', color: { rgb: 'CCCCCC' } },
      bottom: { style: 'thin', color: { rgb: 'CCCCCC' } },
      left: { style: 'thin', color: { rgb: 'CCCCCC' } },
      right: { style: 'thin', color: { rgb: 'CCCCCC' } }
    }
  };

  // Apply header styles
  columns.forEach((_, index) => {
    const cellRef = XLSX.utils.encode_cell({ r: 0, c: index });
    if (worksheet[cellRef]) {
      worksheet[cellRef].s = headerStyle;
    }
  });

  // Apply cell styles to data rows
  for (let rowIndex = 1; rowIndex <= rows.length; rowIndex++) {
    columns.forEach((_, colIndex) => {
      const cellRef = XLSX.utils.encode_cell({ r: rowIndex, c: colIndex });
      if (worksheet[cellRef]) {
        worksheet[cellRef].s = cellStyle;
      }
    });
  }

  // Set column widths
  worksheet['!cols'] = columns.map(col => ({ wch: col.width }));

  // Create workbook
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Data');

  // Generate file
  const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
  const blob = new Blob([wbout], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  });

  // Download
  await downloadBlob(blob, fileName);
}
```

### 2. File Download with File System Access API

```typescript
/**
 * Download blob with native save dialog (Chrome/Edge) or fallback
 */
async function downloadBlob(blob: Blob, fileName: string): Promise<boolean> {
  // Try File System Access API (Chrome/Edge)
  if ('showSaveFilePicker' in window) {
    try {
      const handle = await (window as any).showSaveFilePicker({
        suggestedName: fileName,
        types: [{
          description: 'Excel Files',
          accept: {
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx']
          }
        }]
      });

      const writable = await handle.createWritable();
      await writable.write(blob);
      await writable.close();

      return true; // User saved the file
    } catch (err: any) {
      if (err.name === 'AbortError') {
        return false; // User cancelled
      }
      throw err;
    }
  }

  // Fallback: automatic download
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);

  return true;
}
```

### 3. Complete Export Example

```typescript
const handleExport = async () => {
  const recordsToExport = records.filter(r => r.status === 'ready-to-export');

  if (recordsToExport.length === 0) {
    setToast({ message: 'No records to export', type: 'error' });
    return;
  }

  const columns: ExportColumn[] = [
    { key: 'index', header: 'No.', width: 6 },
    { key: 'url', header: 'Product URL', width: 45 },
    { key: 'description', header: 'Description', width: 120 }
  ];

  const data = recordsToExport.map((record, index) => ({
    index: index + 1,
    url: record.fields['URL'] || '',
    description: record.fields['Description'] || ''
  }));

  const timestamp = new Date().toISOString().slice(0, 10);
  const fileName = `export_${timestamp}.xlsx`;

  try {
    const saved = await exportToExcel(data, columns, fileName);

    if (saved) {
      // Update record statuses after successful export
      for (const record of recordsToExport) {
        await updateRecordStatus(record.id, 'exported');
      }
      setToast({ message: `Exported ${data.length} records`, type: 'success' });
    } else {
      setToast({ message: 'Export cancelled', type: 'error' });
    }
  } catch (error) {
    setToast({ message: 'Export failed', type: 'error' });
  }
};
```

## Style Reference

### Colors (RGB format without #)

```typescript
// Common colors
const colors = {
  indigo: '4F46E5',
  emerald: '10B981',
  amber: 'F59E0B',
  rose: 'F43F5E',
  teal: '14B8A6',
  white: 'FFFFFF',
  black: '000000',
  gray: 'CCCCCC'
};
```

### Font Styles

```typescript
const font = {
  bold: true,
  italic: true,
  underline: true,
  strike: true,
  color: { rgb: 'FFFFFF' },
  sz: 11, // font size
  name: 'Arial' // font name
};
```

### Fill (Background)

```typescript
const fill = {
  fgColor: { rgb: '4F46E5' } // foreground color
};
```

### Alignment

```typescript
const alignment = {
  horizontal: 'center', // 'left' | 'center' | 'right'
  vertical: 'center',   // 'top' | 'center' | 'bottom'
  wrapText: true,
  textRotation: 90      // degrees
};
```

### Borders

```typescript
const border = {
  top: { style: 'thin', color: { rgb: '000000' } },
  bottom: { style: 'thin', color: { rgb: '000000' } },
  left: { style: 'thin', color: { rgb: '000000' } },
  right: { style: 'thin', color: { rgb: '000000' } }
};
// styles: 'thin' | 'medium' | 'thick' | 'dotted' | 'dashed'
```

## Timestamp in Filename

```typescript
function getTimestamp(): string {
  const now = new Date();
  const date = now.toISOString().slice(0, 10); // YYYY-MM-DD
  const time = now.toTimeString().slice(0, 8).replace(/:/g, '-'); // HH-MM-SS
  return `${date}_${time}`;
}

const fileName = `export_${getTimestamp()}.xlsx`;
// Result: export_2024-01-15_14-30-45.xlsx
```

## Polish Number Formatting

```typescript
function formatCount(count: number): string {
  if (count === 1) return '1 rekord';
  if (count >= 2 && count <= 4) return `${count} rekordy`;
  return `${count} rekordów`;
}

// Usage:
setToast({
  message: `Exported ${formatCount(recordsToExport.length)}`,
  type: 'success'
});
```

## Dependencies

```json
{
  "dependencies": {
    "xlsx-js-style": "^1.2.0"
  }
}
```

## TypeScript Types

```typescript
// For File System Access API
declare global {
  interface Window {
    showSaveFilePicker?: (options?: {
      suggestedName?: string;
      types?: {
        description: string;
        accept: Record<string, string[]>;
      }[];
    }) => Promise<FileSystemFileHandle>;
  }
}
```

## Best Practices

1. **Validate file type** before parsing
2. **Skip empty rows** when importing
3. **Use appropriate column widths** for content
4. **Handle cancelled saves** gracefully with File System Access API
5. **Format timestamps** in filenames for uniqueness
6. **Show progress** for large exports
7. **Update record status** after successful export

## Pułapki

### 1. Daty z Excela to serial numbers, nie JS Date

Excel przechowuje daty jako liczbę dni od 1900-01-01 (np. `45658` = 2024-12-31). Domyślne parsowanie zwraca tę liczbę, nie obiekt Date.

```typescript
// ❌ Dostaniesz "45658" zamiast daty
const rows = XLSX.utils.sheet_to_json(worksheet);

// ✅ Dodaj cellDates: true przy odczycie
const workbook = XLSX.read(data, { type: 'binary', cellDates: true });
// Teraz komórki z datami zwracają obiekty JS Date
```

### 2. Polskie znaki w CSV — domyślny encoding to UTF-8 bez BOM

Excel na Windows otwiera CSV w ANSI — polskie znaki (ą, ę, ś) wyglądają jak krzaki. Trzeba dodać BOM na początku pliku.

```typescript
// ❌ Excel pokaże "ZaÅ‚Ä…cznik" zamiast "Załącznik"
const csv = XLSX.utils.sheet_to_csv(worksheet);
const blob = new Blob([csv], { type: 'text/csv' });

// ✅ Dodaj UTF-8 BOM
const BOM = '\uFEFF';
const blob = new Blob([BOM + csv], { type: 'text/csv;charset=utf-8' });
```

Uwaga: problem dotyczy tylko eksportu do CSV. Format `.xlsx` obsługuje UTF-8 natywnie.

### 3. Duże pliki (5000+ wierszy) blokują main thread

`XLSX.read()` i `XLSX.write()` są synchroniczne i blokują UI. Przy dużych plikach przeglądarka zamiera na kilka sekund.

```typescript
// ❌ Blokuje UI — użytkownik myśli, że aplikacja się zawiesiła
const workbook = XLSX.read(data, { type: 'binary' });

// ✅ Przenieś do Web Workera lub podziel na chunki z setTimeout
// Minimum: pokaż spinner PRZED wywołaniem XLSX.read()
setLoading(true);
requestAnimationFrame(() => {
  const workbook = XLSX.read(data, { type: 'binary' });
  setLoading(false);
});
```

### 4. Brak walidacji struktury importowanego pliku

Użytkownik wgra plik z innymi kolumnami niż oczekiwane — aplikacja się wysypie lub zaimportuje śmieci.

```typescript
// ❌ Zakłada, że kolumna "Nazwa" istnieje
const name = rows[0]['Nazwa'];

// ✅ Sprawdź wymagane kolumny przed przetwarzaniem
const requiredHeaders = ['Nazwa', 'Cena', 'Kod EAN'];
const missing = requiredHeaders.filter(h => !headers.includes(h));
if (missing.length > 0) {
  throw new Error(`Brak wymaganych kolumn: ${missing.join(', ')}`);
}
```

### 5. Utrata stylów przy odczycie i ponownym zapisie istniejącego pliku

`xlsx-js-style` nie zachowuje oryginalnych stylów komórek przy odczycie. Jeśli wczytujesz plik użytkownika, modyfikujesz dane i zapisujesz — formatowanie zniknie. Style można dodawać tylko do nowo tworzonych arkuszy. Jeśli musisz zachować oryginalne formatowanie, rozważ bibliotekę `exceljs`.

### 6. File System Access API nie działa w Firefox i Safari

`showSaveFilePicker` jest dostępne TYLKO w Chromium (Chrome, Edge, Opera). W Firefox/Safari wywołanie rzuci błąd. Skill zawiera fallback, ale pamiętaj, żeby ZAWSZE go implementować — nie polegaj na samym `showSaveFilePicker`.

### 7. Wartości liczbowe importowane jako string

Gdy używasz `header: 1` z `defval: ''`, wszystkie wartości są konwertowane do stringów. Kolumny z cenami, ilościami, kodami EAN tracą typ liczbowy.

```typescript
// ❌ Cena to "29.99" (string) — porównania i sortowanie nie działają poprawnie
const price = row['Cena']; // "29.99"

// ✅ Parsuj jawnie po imporcie
const price = parseFloat(row['Cena']) || 0;
// Lub nie używaj defval: '' i obsłuż undefined osobno
```

### 8. Komórki scalone (merged cells) psują parsowanie

Jeśli importowany plik ma scalone komórki (np. nagłówki grupujące), `sheet_to_json` widzi wartość tylko w pierwszej komórce — reszta jest pusta. Sprawdź `worksheet['!merges']` i rozwiń scalone komórki przed parsowaniem, albo poinformuj użytkownika, że plik nie może zawierać scalonych komórek.
