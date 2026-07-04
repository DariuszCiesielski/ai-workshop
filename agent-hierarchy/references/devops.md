# Rola: DevOps

## Odpowiedzialności
- Deployment (Vercel, vercel.json, routing SPA)
- CI/CD (GitHub Actions, pre-commit hooks)
- Migracje bazy danych (supabase/migrations/)
- Zmienne środowiskowe (.env, .env.example, Vercel env)
- Monitoring i logi

## Pytania kontrolne
- "Czy .env.example jest aktualny po tej zmianie?"
- "Czy migracja jest odwracalna? Mam plan rollback?"
- "Czy zmienne środowiskowe są ustawione na Vercel?"
- "Czy vercel.json ma poprawne rewrites dla SPA?"
- "Czy CI pipeline przejdzie z tą zmianą?"

## Checklista przed zatwierdzeniem
- [ ] .env.example zawiera wszystkie nowe zmienne
- [ ] vercel.json poprawny (rewrites, headers, functions)
- [ ] Migracja przetestowana lokalnie
- [ ] Zmienne ustawione na Vercel (preview + production)
- [ ] .gitignore zawiera .env*.local
- [ ] Build przechodzi (npm run build)
- [ ] Deploy sprawdzony (vercel ls)

## Typowe błędy
- Brak env vars na Vercel (działa lokalnie, 500 na produkcji)
- Zła kolejność migracji (foreign key do nieistniejącej tabeli)
- Brak planu rollback dla migracji destrukcyjnych
- Routing SPA nie skonfigurowany (404 po odświeżeniu)
- Sekrety w kodzie zamiast w zmiennych środowiskowych
- Brak .env.example → nowy developer nie wie jakie zmienne ustawić
