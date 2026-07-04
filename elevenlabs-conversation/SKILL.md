---
name: elevenlabs-conversation
description: Integracja z ElevenLabs Conversational AI — rozmowy głosowe z agentami AI. Hook custom, zarządzanie transkryptami, uprawnienia mikrofonu, obsługa statusu połączenia. Używaj przy budowaniu aplikacji z voice chat.
---

# ElevenLabs Conversational AI Integration

This skill provides patterns for integrating ElevenLabs Conversational AI into React applications for voice conversations with AI agents.

## When to Use

- Building voice chat with AI agents
- Implementing real-time conversation transcripts
- Managing microphone permissions in React
- Handling WebSocket connection states

## Prerequisites

### Installation

```bash
npm install @elevenlabs/react
```

### Environment Variables

```env
VITE_ELEVENLABS_AGENT_ID=agent_xxxx
VITE_ELEVENLABS_API_KEY=sk_xxxx  # Optional, for signed URLs
```

## Implementation

### 1. Custom Hook - useElevenLabsConversation

```typescript
// hooks/useElevenLabsConversation.ts
import { useState, useCallback, useMemo } from 'react';
import { useConversation, Role } from '@elevenlabs/react';

// Types
export type ConversationStatus = 'idle' | 'connecting' | 'connected' | 'disconnecting' | 'error';

export interface TranscriptMessage {
  id: string;
  text: string;
  source: 'user' | 'ai';
  timestamp: Date;
}

export interface ConversationError {
  message: string;
  code?: string;
}

export interface UseElevenLabsConversationReturn {
  // State
  status: ConversationStatus;
  transcript: TranscriptMessage[];
  error: ConversationError | null;
  conversationId: string | null;
  isSpeaking: boolean;
  isMuted: boolean;

  // Actions
  startSession: () => Promise<void>;
  endSession: () => Promise<void>;
  toggleMute: () => void;
  sendMessage: (text: string) => void;
  clearError: () => void;
  clearTranscript: () => void;
}

// Helper to generate unique message IDs
const generateMessageId = (): string => {
  return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
};

// Map SDK status to internal status
const mapStatus = (sdkStatus: string): ConversationStatus => {
  switch (sdkStatus) {
    case 'connected':
      return 'connected';
    case 'connecting':
      return 'connecting';
    case 'disconnecting':
      return 'disconnecting';
    case 'disconnected':
      return 'idle';
    default:
      return 'idle';
  }
};

export function useElevenLabsConversation(): UseElevenLabsConversationReturn {
  const agentId = import.meta.env.VITE_ELEVENLABS_AGENT_ID || '';

  // Internal state
  const [transcript, setTranscript] = useState<TranscriptMessage[]>([]);
  const [internalStatus, setInternalStatus] = useState<ConversationStatus>('idle');
  const [error, setError] = useState<ConversationError | null>(null);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [isSpeaking, setIsSpeaking] = useState(false);

  // ElevenLabs conversation hook
  const conversation = useConversation({
    onConnect: ({ conversationId: id }) => {
      console.log('[ElevenLabs] Connected:', id);
      setConversationId(id);
      setError(null);
      setTranscript([]); // Clear transcript on new session
      setInternalStatus('connected');
    },

    onDisconnect: () => {
      console.log('[ElevenLabs] Disconnected');
      setInternalStatus('idle');
      setIsSpeaking(false);
    },

    onMessage: ({ message, source }: { message: string; source: Role }) => {
      console.log('[ElevenLabs] Message:', source, message);
      const newMessage: TranscriptMessage = {
        id: generateMessageId(),
        text: message,
        source: source === 'ai' ? 'ai' : 'user',
        timestamp: new Date(),
      };
      setTranscript((prev) => [...prev, newMessage]);
    },

    onError: (err: Error) => {
      console.error('[ElevenLabs] Error:', err);
      setError({
        message: err.message || 'Wystąpił błąd podczas rozmowy',
        code: 'CONVERSATION_ERROR',
      });
      setInternalStatus('error');
    },

    onStatusChange: ({ status: sdkStatus }) => {
      console.log('[ElevenLabs] Status:', sdkStatus);
      const mappedStatus = mapStatus(sdkStatus);
      // Don't override error status unless reconnecting
      if (internalStatus !== 'error' || mappedStatus === 'connected') {
        setInternalStatus(mappedStatus);
      }
    },

    onModeChange: ({ mode }) => {
      // mode: 'speaking' | 'listening'
      setIsSpeaking(mode === 'speaking');
    },
  });

  // Start conversation session
  const startSession = useCallback(async () => {
    if (!agentId) {
      setError({
        message: 'Brak identyfikatora agenta (VITE_ELEVENLABS_AGENT_ID)',
        code: 'MISSING_AGENT_ID',
      });
      setInternalStatus('error');
      return;
    }

    try {
      setError(null);
      setInternalStatus('connecting');

      // Request microphone permission
      await navigator.mediaDevices.getUserMedia({ audio: true });

      // Start ElevenLabs session
      await conversation.startSession({ agentId });
    } catch (err) {
      console.error('[ElevenLabs] Start session error:', err);

      if (err instanceof Error) {
        if (err.name === 'NotAllowedError') {
          setError({
            message: 'Brak dostępu do mikrofonu. Udziel uprawnień w przeglądarce.',
            code: 'MICROPHONE_PERMISSION_DENIED',
          });
        } else if (err.name === 'NotFoundError') {
          setError({
            message: 'Nie znaleziono mikrofonu. Podłącz mikrofon i spróbuj ponownie.',
            code: 'MICROPHONE_NOT_FOUND',
          });
        } else {
          setError({
            message: err.message || 'Nie udało się rozpocząć rozmowy',
            code: 'SESSION_START_ERROR',
          });
        }
      } else {
        setError({
          message: 'Nieznany błąd podczas uruchamiania rozmowy',
          code: 'UNKNOWN_ERROR',
        });
      }

      setInternalStatus('error');
    }
  }, [conversation, agentId]);

  // End conversation session
  const endSession = useCallback(async () => {
    try {
      await conversation.endSession();
      setInternalStatus('idle');
      setIsSpeaking(false);
    } catch (err) {
      console.error('[ElevenLabs] End session error:', err);
    }
  }, [conversation]);

  // Toggle microphone mute
  const toggleMute = useCallback(() => {
    if (conversation.setMicMuted) {
      const currentMuted = conversation.micMuted ?? false;
      conversation.setMicMuted(!currentMuted);
    }
  }, [conversation]);

  // Send text message to agent
  const sendMessage = useCallback((text: string) => {
    if (conversation.status === 'connected') {
      conversation.sendUserMessage(text);
    }
  }, [conversation]);

  // Clear error
  const clearError = useCallback(() => {
    setError(null);
    if (internalStatus === 'error') {
      setInternalStatus('idle');
    }
  }, [internalStatus]);

  // Clear transcript
  const clearTranscript = useCallback(() => {
    setTranscript([]);
  }, []);

  // Memoize return value
  return useMemo(
    () => ({
      status: internalStatus,
      transcript,
      error,
      conversationId,
      isSpeaking,
      isMuted: conversation.micMuted ?? false,
      startSession,
      endSession,
      toggleMute,
      sendMessage,
      clearError,
      clearTranscript,
    }),
    [
      internalStatus,
      transcript,
      error,
      conversationId,
      isSpeaking,
      conversation.micMuted,
      startSession,
      endSession,
      toggleMute,
      sendMessage,
      clearError,
      clearTranscript,
    ]
  );
}
```

### 2. Chat Page Component

```typescript
// pages/Chat.tsx
import { useTranslation } from 'react-i18next';
import { useElevenLabsConversation } from '@/hooks/useElevenLabsConversation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { TranscriptPanel } from '@/components/chat/TranscriptPanel';
import { Mic, MicOff, Phone, PhoneOff, AlertCircle, Loader2 } from 'lucide-react';

export function Chat() {
  const { t } = useTranslation('chat');
  const {
    status,
    transcript,
    error,
    isSpeaking,
    isMuted,
    startSession,
    endSession,
    toggleMute,
    clearError,
  } = useElevenLabsConversation();

  const isConnected = status === 'connected';
  const isConnecting = status === 'connecting';
  const isError = status === 'error';

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('title')}</h1>
          <p className="text-muted-foreground">{t('description')}</p>
        </div>
      </div>

      {/* Error Alert */}
      {isError && error && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{error.message}</AlertDescription>
        </Alert>
      )}

      {/* Main Chat Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>{t('conversation')}</span>
            {/* Status indicator */}
            <div className="flex items-center gap-2">
              <div
                className={`h-2 w-2 rounded-full ${
                  isConnected
                    ? 'bg-green-500'
                    : isConnecting
                    ? 'bg-yellow-500 animate-pulse'
                    : 'bg-gray-400'
                }`}
              />
              <span className="text-sm text-muted-foreground">
                {isConnected && t('status.connected')}
                {isConnecting && t('status.connecting')}
                {status === 'idle' && t('status.idle')}
                {isError && t('status.error')}
              </span>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Transcript */}
          <TranscriptPanel
            messages={transcript}
            isConnected={isConnected}
            isSpeaking={isSpeaking}
          />

          {/* Controls */}
          <div className="flex justify-center gap-4 pt-4 border-t">
            {!isConnected ? (
              <Button
                onClick={startSession}
                disabled={isConnecting}
                size="lg"
                className="gap-2"
              >
                {isConnecting ? (
                  <>
                    <Loader2 className="h-5 w-5 animate-spin" />
                    {t('actions.connecting')}
                  </>
                ) : (
                  <>
                    <Phone className="h-5 w-5" />
                    {t('actions.start')}
                  </>
                )}
              </Button>
            ) : (
              <>
                <Button
                  onClick={toggleMute}
                  variant={isMuted ? 'secondary' : 'outline'}
                  size="lg"
                  className="gap-2"
                >
                  {isMuted ? (
                    <>
                      <MicOff className="h-5 w-5" />
                      {t('actions.unmute')}
                    </>
                  ) : (
                    <>
                      <Mic className="h-5 w-5" />
                      {t('actions.mute')}
                    </>
                  )}
                </Button>
                <Button
                  onClick={endSession}
                  variant="destructive"
                  size="lg"
                  className="gap-2"
                >
                  <PhoneOff className="h-5 w-5" />
                  {t('actions.end')}
                </Button>
              </>
            )}
          </div>

          {/* Speaking indicator */}
          {isConnected && (
            <div className="flex justify-center">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                {isSpeaking ? (
                  <>
                    <Mic className="h-4 w-4 text-green-500 animate-pulse" />
                    <span>{t('status.aiSpeaking')}</span>
                  </>
                ) : (
                  <>
                    <MicOff className="h-4 w-4" />
                    <span>{t('status.listening')}</span>
                  </>
                )}
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
```

### 3. Transcript Panel Component

```typescript
// components/chat/TranscriptPanel.tsx
import { useEffect, useRef } from 'react';
import { cn } from '@/lib/utils';
import type { TranscriptMessage } from '@/hooks/useElevenLabsConversation';
import { Bot, User, MessageCircle } from 'lucide-react';

interface TranscriptPanelProps {
  messages: TranscriptMessage[];
  isConnected: boolean;
  isSpeaking: boolean;
}

export function TranscriptPanel({
  messages,
  isConnected,
  isSpeaking,
}: TranscriptPanelProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  // Empty state
  if (messages.length === 0) {
    return (
      <div className="h-[400px] flex flex-col items-center justify-center text-muted-foreground">
        <MessageCircle className="h-12 w-12 mb-4 opacity-50" />
        <p className="text-center">
          {isConnected
            ? 'Rozpocznij rozmowę - powiedz coś do mikrofonu'
            : 'Kliknij "Rozpocznij rozmowę" aby połączyć się z agentem'}
        </p>
      </div>
    );
  }

  return (
    <div
      ref={scrollRef}
      className="h-[400px] overflow-y-auto space-y-4 p-4 bg-muted/30 rounded-lg"
    >
      {messages.map((message) => (
        <div
          key={message.id}
          className={cn(
            'flex gap-3',
            message.source === 'user' ? 'justify-end' : 'justify-start'
          )}
        >
          {/* Avatar for AI */}
          {message.source === 'ai' && (
            <div className="flex-shrink-0 h-8 w-8 rounded-full bg-primary flex items-center justify-center">
              <Bot className="h-4 w-4 text-primary-foreground" />
            </div>
          )}

          {/* Message bubble */}
          <div
            className={cn(
              'max-w-[70%] rounded-lg px-4 py-2',
              message.source === 'user'
                ? 'bg-primary text-primary-foreground'
                : 'bg-card border'
            )}
          >
            <p className="text-sm">{message.text}</p>
            <span className="text-xs opacity-70 mt-1 block">
              {message.timestamp.toLocaleTimeString('pl-PL', {
                hour: '2-digit',
                minute: '2-digit',
              })}
            </span>
          </div>

          {/* Avatar for User */}
          {message.source === 'user' && (
            <div className="flex-shrink-0 h-8 w-8 rounded-full bg-secondary flex items-center justify-center">
              <User className="h-4 w-4" />
            </div>
          )}
        </div>
      ))}

      {/* Typing indicator when AI is speaking */}
      {isSpeaking && (
        <div className="flex gap-3">
          <div className="flex-shrink-0 h-8 w-8 rounded-full bg-primary flex items-center justify-center">
            <Bot className="h-4 w-4 text-primary-foreground" />
          </div>
          <div className="bg-card border rounded-lg px-4 py-2">
            <div className="flex gap-1">
              <span className="h-2 w-2 rounded-full bg-muted-foreground animate-bounce" />
              <span className="h-2 w-2 rounded-full bg-muted-foreground animate-bounce delay-100" />
              <span className="h-2 w-2 rounded-full bg-muted-foreground animate-bounce delay-200" />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

### 4. Translation Keys

```json
// locales/pl/chat.json
{
  "title": "Rozmowa z agentem",
  "description": "Porozmawiaj głosowo z asystentem AI",
  "conversation": "Rozmowa",
  "status": {
    "idle": "Nieaktywny",
    "connecting": "Łączenie...",
    "connected": "Połączony",
    "error": "Błąd połączenia",
    "aiSpeaking": "Agent mówi...",
    "listening": "Słucham..."
  },
  "actions": {
    "start": "Rozpocznij rozmowę",
    "end": "Zakończ rozmowę",
    "connecting": "Łączenie...",
    "mute": "Wycisz",
    "unmute": "Odcisz"
  },
  "errors": {
    "microphonePermission": "Brak dostępu do mikrofonu",
    "microphoneNotFound": "Nie znaleziono mikrofonu",
    "connectionFailed": "Nie udało się połączyć z agentem"
  }
}
```

## Advanced Patterns

### Signed URL Authentication

For production apps, use signed URLs:

```typescript
// hooks/useSignedUrl.ts
import { useQuery } from '@tanstack/react-query';

export function useSignedUrl(agentId: string) {
  return useQuery({
    queryKey: ['elevenlabs-signed-url', agentId],
    queryFn: async () => {
      const response = await fetch('/api/elevenlabs/signed-url', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ agentId }),
      });

      if (!response.ok) throw new Error('Failed to get signed URL');
      return response.json();
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
    enabled: !!agentId,
  });
}

// Usage in startSession
const { data: signedUrl } = useSignedUrl(agentId);

const startSession = useCallback(async () => {
  await conversation.startSession({
    signedUrl: signedUrl?.url,
  });
}, [conversation, signedUrl]);
```

### Voice Activity Detection

```typescript
// Detect when user is speaking
const conversation = useConversation({
  onModeChange: ({ mode }) => {
    // mode: 'speaking' (AI) | 'listening' (waiting for user)
    setIsSpeaking(mode === 'speaking');
  },
});
```

## File Structure

```
src/
├── hooks/
│   └── useElevenLabsConversation.ts
├── components/
│   └── chat/
│       ├── TranscriptPanel.tsx
│       └── VoiceIndicator.tsx
├── pages/
│   └── Chat.tsx
└── locales/
    └── pl/
        └── chat.json
```

## Best Practices

1. **Request microphone permission** before starting session
2. **Handle all error cases** - permission denied, device not found, connection errors
3. **Show clear status indicators** - connecting, connected, speaking, listening
4. **Auto-scroll transcript** to show latest messages
5. **Provide visual feedback** when AI is speaking
6. **Clean up on unmount** - end session when component unmounts
7. **Use unique message IDs** for React key prop

## Pułapki

### 1. Brak cleanup sesji przy odmontowaniu komponentu

Jeśli użytkownik przejdzie na inną stronę w trakcie rozmowy, połączenie WebSocket zostaje otwarte, mikrofon nagrawa w tle, a przy powrocie `useConversation` tworzy DRUGĄ sesję.

```tsx
// ❌ Brak cleanup — wyciek połączenia i mikrofonu
export function Chat() {
  const { startSession } = useElevenLabsConversation();
  return <button onClick={startSession}>Start</button>;
}

// ✅ useEffect z cleanup kończącym sesję
useEffect(() => {
  return () => {
    if (conversation.status === 'connected') {
      conversation.endSession();
    }
  };
}, [conversation]);
```

### 2. `getUserMedia` wywoływane PO `startSession`

SDK ElevenLabs **nie** prosi o mikrofon automatycznie — trzeba to zrobić PRZED `startSession`. Jeśli wywołasz `startSession` bez wcześniejszego `getUserMedia`, sesja się połączy, ale agent nie usłyszy użytkownika (brak streamu audio). Żadnego błędu nie zobaczysz.

```ts
// ❌ startSession bez getUserMedia — cisza po stronie użytkownika
await conversation.startSession({ agentId });

// ✅ Najpierw mikrofon, potem sesja
await navigator.mediaDevices.getUserMedia({ audio: true });
await conversation.startSession({ agentId });
```

### 3. Nieobsłużony status `disconnected` vs `error`

SDK zwraca status `disconnected` zarówno przy normalnym zakończeniu, jak i przy zerwaniu połączenia (np. utrata internetu). Jeśli mapujesz `disconnected` → `idle` bez rozróżnienia, użytkownik nie dowie się o zerwaniu.

```ts
// ❌ Zawsze idle — utrata połączenia wygląda jak normalne zakończenie
case 'disconnected': return 'idle';

// ✅ Sprawdź czy rozłączenie było zamierzone
onDisconnect: () => {
  if (!userInitiatedDisconnect.current) {
    setError({ message: 'Połączenie zostało przerwane', code: 'UNEXPECTED_DISCONNECT' });
    setInternalStatus('error');
  } else {
    setInternalStatus('idle');
  }
}
```

### 4. Podwójne kliknięcie "Rozpocznij rozmowę"

Jeśli przycisk nie jest zablokowany podczas `connecting`, użytkownik może kliknąć dwa razy i uruchomić dwie równoległe sesje. Efekt: dwa strumienie audio, echo, podwójne wiadomości w transkrypcie.

```tsx
// ❌ Tylko wizualne disabled — brak ochrony w logice
<Button onClick={startSession}>Start</Button>

// ✅ Guard w hooku + disabled na przycisku
const startSession = useCallback(async () => {
  if (internalStatus === 'connecting' || internalStatus === 'connected') return;
  // ...reszta logiki
}, [internalStatus]);
```

### 5. `onMessage` nie rozróżnia wiadomości częściowych od pełnych

Callback `onMessage` z SDK jest wywoływany dla KAŻDEGO fragmentu transkrypcji (partial transcript). Jeśli dodajesz każdy callback jako nową wiadomość, transkrypt będzie wyglądał jak: "Cz", "Cześ", "Cześć", "Cześć, jak". Trzeba aktualizować ostatnią wiadomość danego źródła zamiast dodawać nową.

```ts
// ❌ Każdy fragment jako osobna wiadomość
onMessage: ({ message, source }) => {
  setTranscript(prev => [...prev, { text: message, source }]);
};

// ✅ Aktualizuj ostatnią wiadomość tego samego źródła (partial update)
onMessage: ({ message, source }) => {
  setTranscript(prev => {
    const last = prev[prev.length - 1];
    if (last && last.source === (source === 'ai' ? 'ai' : 'user') && !last.isFinal) {
      return [...prev.slice(0, -1), { ...last, text: message }];
    }
    return [...prev, { id: generateMessageId(), text: message, source: source === 'ai' ? 'ai' : 'user', timestamp: new Date(), isFinal: false }];
  });
};
```

### 6. Brak obsługi wygaśnięcia signed URL

Signed URL ma TTL (domyślnie 5 minut). Jeśli użytkownik otworzy stronę, poczeka 10 minut i kliknie "Rozpocznij" — dostanie cichy błąd połączenia. `useQuery` ze `staleTime: 5min` nie wystarczy — trzeba odświeżyć URL tuż przed `startSession`.

```ts
// ❌ Stały URL z cache — po 5 min wygasa
const { data: signedUrl } = useSignedUrl(agentId);
await conversation.startSession({ signedUrl: signedUrl?.url });

// ✅ Pobierz świeży URL bezpośrednio przed startem
const startSession = useCallback(async () => {
  const freshUrl = await refetchSignedUrl();
  await conversation.startSession({ signedUrl: freshUrl.data?.url });
}, []);
```

### 7. `conversation.micMuted` jest `undefined` przed pierwszą sesją

Przed wywołaniem `startSession` property `micMuted` zwraca `undefined`, nie `false`. Jeśli użyjesz tego w UI bez fallbacku, przycisk mute/unmute pokaże nieprawidłowy stan.

```ts
// ❌ Może być undefined → UI się psuje
isMuted: conversation.micMuted,

// ✅ Zawsze boolean
isMuted: conversation.micMuted ?? false,
```
