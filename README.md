# Mobilní Aplikace Repetito
## Závěrečný maturitní projekt

## 1. Definice cíle a funkčnosti aplikace

**Hlavní cíle projektu:** 
- Vytvořit aplikaci, která pomáhá uživatelům učit se efektivněji na principu spaced repetition (učení s opakovaným rozestupem)
- Pokusit se vytvořit reálný produkt a uvést ho na trh

**Podcíle projektu:** 
- Kompletní návrh celé aplikace, včetně Architektury, User Flow, tvorby Wireframů v aplikaci Figma
- Naprogramovat celou aplikaci ve frameworku Flutter (programovací jazyk Dart)
- Vytvořit landing page pro finální produkt
- Vydat aplikaci do světa (přidat na Google Play, App Store)

## 2. Aktuální funkce aplikace

- Přihlášení přes Google účet
- Vytváření a správa balíčků kartiček
- Přidávání a mazání kartiček
- Studium kartiček s využitím spaced repetition
- Practice mód pro procvičování bez ukládání pokroku
- Automatické plánování opakování na základě výkonu
- Možnost vrátit zpět smazané balíčky a kartičky
- Intuitivní uživatelské rozhraní
- Real-time aktualizace dat

## 3. Plánované funkce

- Statistiky a sledování pokroku
- Možnost přidávat obrázky či zvuky na kartičky
- Integrace AI funkcí pro generování kartiček
- Komunitní funkce – sdílení sad kartiček
- Přidání funkce automatického překladu
- Offline podpora
- Gamifikace (achievementy, denní cíle)
- Složky pro organizaci balíčků

## 4. Technologie

- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod, Flutter Hooks
- **Navigace:** GoRouter
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **Generování kódu:** Freezed, JSON Serializable
- **Verzování:** Git

## 5. Instalace a spuštění

1. Naklonujte repozitář:
```bash
git clone https://github.com/deathfrost12/repetito.git
```

2. Nainstalujte závislosti:
```bash
flutter pub get
```

3. Vygenerujte potřebný kód:
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Spusťte aplikaci:
```bash
flutter run
```

## 6. Struktura projektu

```
lib/
  ├── core/            # Základní konfigurace a konstanty
  │   ├── constants/   # Konstanty aplikace
  │   └── router/      # Konfigurace routeru
  ├── data/            # Repository vrstva
  │   └── repositories/# Repozitáře pro práci s daty
  ├── domain/          # Entity a business logika
  │   ├── entities/    # Datové modely
  │   └── enums/       # Enumy
  └── presentation/    # UI vrstva
      ├── providers/   # Riverpod providers
      └── screens/     # Obrazovky aplikace
```

## 7. Databázové schéma

### Tabulky
- **decks** - Balíčky kartiček
- **cards** - Kartičky
- **study_progress** - Pokrok ve studiu

### Vztahy
- Deck 1:N Cards
- Card 1:N StudyProgress
- User 1:N Decks

## 8. Použité knihovny

### Hlavní
- flutter_riverpod: State management
- go_router: Navigace
- supabase_flutter: Backend
- flutter_hooks: Lifecycle management
- freezed: Immutable třídy

### Vývojové
- build_runner: Generování kódu
- json_serializable: JSON serializace
- riverpod_generator: Generování providerů

## 9. Autor

Daniel Holeš
- GitHub: [@deathfrost12](https://github.com/deathfrost12)
- Email: holes.daniel@gmail.com
