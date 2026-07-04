---
name: postiz-account-setup
description: Zakładanie konta w self-hosted Postiz (diagnostyka + fix typowych problemów + generowanie API key)
triggers:
  - "załóż konto postiz"
  - "postiz account"
  - "postiz api key"
  - "nowe konto postiz"
  - "postiz nie działa"
  - "postiz 502"
  - "postiz backend nie startuje"
---

# Postiz Account Setup & Troubleshooting

## Kiedy używać

- Zakładanie konta administratora lub klienta w self-hosted Postiz
- Generowanie API key do integracji
- Diagnostyka problemów z Postiz (502, backend crash, CORS)

## Wymagania

- Postiz zainstalowany przez Docker Compose (z Temporal, PostgreSQL, Redis)
- Dostęp SSH do serwera
- `DISABLE_REGISTRATION=false` w `.env` (tymczasowo, na czas rejestracji)

## Krok 1: Sprawdź czy stack działa

```bash
cd /opt/postiz && docker compose ps
```

Oczekiwane: 6 kontenerów Up (postiz, postiz-postgres, postiz-redis, temporal, temporal-postgresql, temporal-ui).

## Krok 2: Sprawdź backend Postiz

Postiz wewnętrznie uruchamia 3 procesy przez PM2: frontend (port 4200), backend (port 3000), orchestrator.

```bash
# Sprawdź status procesów
docker exec postiz pm2 jlist 2>/dev/null | grep -o '"name":"[^"]*"\|"status":"[^"]*"\|"restart_time":[0-9]*'

# Sprawdź czy backend nasłuchuje na porcie 3000
docker exec postiz ss -tlnp
```

**Oczekiwane porty wewnątrz kontenera:**
- 5000 — nginx (reverse proxy wewnętrzny)
- 4200 — Next.js frontend
- 3000 — NestJS backend API

Jeśli port 3000 nie nasłuchuje — backend nie wystartował. Przejdź do sekcji "Typowe problemy".

## Krok 3: Włącz rejestrację (jeśli wyłączona)

```bash
cd /opt/postiz
grep "DISABLE_REGISTRATION" .env
# Jeśli =true, zmień tymczasowo:
sed -i 's/DISABLE_REGISTRATION=true/DISABLE_REGISTRATION=false/' .env
docker compose restart postiz
sleep 20
```

## Krok 4: Zarejestruj konto

### Przez przeglądarkę (preferowane)
1. Otwórz `https://<DOMENA>` (np. `https://social.aiwbiznesie.dev`)
2. Wypełnij formularz rejestracji
3. Zaloguj się

### Przez curl (jeśli przeglądarka nie działa)
```bash
curl -s -X POST http://127.0.0.1:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"USER@EMAIL","password":"HASLO","company":"NAZWA_FIRMY"}' | jq .
```

**UWAGA**: Nie używaj `localhost:5000` w przeglądarce — CORS zablokuje zapytania do API, bo `NEXT_PUBLIC_BACKEND_URL` wskazuje na publiczną domenę. Zawsze używaj publicznego adresu HTTPS.

## Krok 5: Wygeneruj API key

1. Zaloguj się do Postiz
2. Settings -> API Keys
3. Wygeneruj nowy klucz
4. Skopiuj klucz (nie da się go potem zobaczyć ponownie)

## Krok 6: Wyłącz rejestrację

```bash
cd /opt/postiz
sed -i 's/DISABLE_REGISTRATION=false/DISABLE_REGISTRATION=true/' .env
docker compose restart postiz
sleep 20
# Weryfikacja:
grep "DISABLE_REGISTRATION" .env
# Oczekiwane: DISABLE_REGISTRATION=true
```

---

## Typowe problemy

### Problem: Backend nie startuje (port 3000 nie nasłuchuje)

**Diagnostyka:**
```bash
docker exec postiz pm2 logs backend --lines 30 --nostream
```

### Problem: "Unable to create search attributes: cannot have more than 3 search attribute of type Text"

**Przyczyna:** Temporal z PostgreSQL jako visibility store ma limit 3 atrybutów typu Text. Domyślna konfiguracja auto-setup tworzy `CustomTextField` i `CustomStringField`, zabierając 2 z 3 slotów. Postiz potrzebuje więcej.

**Fix:**
```bash
# Sprawdź istniejące atrybuty
docker exec temporal temporal operator search-attribute list --namespace default --address temporal:7233

# Usuń domyślne atrybuty Text (nie są używane przez Postiz)
docker exec temporal temporal operator search-attribute remove --name CustomTextField --namespace default --address temporal:7233 --yes
docker exec temporal temporal operator search-attribute remove --name CustomStringField --namespace default --address temporal:7233 --yes

# Restartuj backend
docker exec postiz pm2 restart backend --update-env
sleep 15

# Sprawdź czy backend wystartował
docker exec postiz pm2 logs backend --lines 5 --nostream
# Oczekiwane: "Backend is running on: http://localhost:3000"
```

### Problem: 502 Bad Gateway z nginx/1.22.1

**Przyczyna:** nginx/1.22.1 to WEWNĘTRZNY serwer w kontenerze Postiz (nie oddzielny nginx na hoście). 502 oznacza, że nginx nie może się połączyć z backendem na porcie 3000.

**Fix:** Rozwiąż problem z backendem (patrz wyżej).

### Problem: CORS przy rejestracji z localhost

**Przyczyna:** Frontend Postiz na `http://localhost:5000` wysyła zapytania do API pod `https://DOMENA/api/...`. Przeglądarka blokuje cross-origin request.

**Fix:** Otwórz Postiz przez publiczny adres HTTPS zamiast localhost:5000. SSH tunnel nie jest potrzebny do rejestracji — wystarczy, że `DISABLE_REGISTRATION=false`.

### Problem: Temporal CLI nie łączy się wewnątrz kontenera

**Fix:** Dodaj `--address temporal:7233` do każdego polecenia:
```bash
docker exec temporal temporal operator search-attribute list --namespace default --address temporal:7233
```

---

## Checklist po zakończeniu

- [ ] Konto istnieje i można się zalogować
- [ ] API key wygenerowany i zapisany
- [ ] `DISABLE_REGISTRATION=true` w `.env`
- [ ] Backend Postiz odpowiada na porcie 3000
- [ ] Stack stabilny (`docker compose ps` — wszystko Up)
