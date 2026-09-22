Jesteś niezależnym, krytycznym recenzentem dokumentacji projektowej. Kontekst zawiera trzy dokumenty jednego projektu: (1) kartę projektu (kontrakt: cel, zakres, kryteria odbioru), (2) spec etapu 2 „Wydatki IT" (architektura, dane, przepływ, błędy, testy), (3) rejestr decyzji (ADR). Projekt: narzędzie, które codziennie przegląda pocztę właściciela jednoosobowej firmy w Polsce, wyławia faktury i obciążenia bez dokumentu, czyta PDF lokalnym modelem, sprawdza kompletność faktury, przelicza po kursie NBP, zapisuje do bazy i na Dysk Google. Etap 1 (demo KSeF) już zamknięty. Warunki brzegowe ustalone przez właściciela (nie kwestionuj ich, oceniaj wykonanie): od 1.09.2026 w przód; zero płatnych API; kurs NBP z ostatniego dnia roboczego przed datą wystawienia; dokumenty na Dysk Google; automat codzienny.

ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]

Potem, po polsku, konkretnie, bez chwalenia:
1. SPRZECZNOŚCI między trzema dokumentami (karta vs spec vs ADR) — cytuj miejsca.
2. LUKI w kryteriach odbioru KRYT-2.1–2.6: co można „zaliczyć" nie dostarczając wartości? Które kryterium nie da się zmierzyć tak, jak opisano?
3. RYZYKA TECHNICZNE przepływu dnia (sekcja 4 specu): co pęknie pierwsze na prawdziwej skrzynce? (np. rozpoznanie faktury regułami, dedup, kursy NBP, katalog do-podpiecia, LaunchAgent).
4. CZEGO SPEC NIE MIERZY, a powinien (np. odsetek maili błędnie rozpoznanych, czas przebiegu, koszt RAM przy lokalnym modelu).
5. NADMIAR: co można wyciąć z etapu 2 bez straty dla celu właściciela (YAGNI).
6. Maksymalnie 3 rekomendacje zmian w kolejności ważności, każda z odwołaniem do konkretnego dokumentu i sekcji.
Nie proponuj płatnych usług w chmurze. Estymaty podawaj w godzinach pracy agenta, nie w dniach.
