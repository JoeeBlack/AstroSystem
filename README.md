# AstroSystem

**Kolejna edycja AstroSystemu stworzonego w IOA.**

Niniejsze repozytorium zawiera skrypt `install_packages.sh`, który automatyzuje konfigurację środowiska analizy astronomicznej na systemach Linux (Ubuntu/Debian).


## 1. Wymagania wstępne
- **System operacyjny:** Ubuntu 20.04 LTS, 22.04 LTS lub Debian 11/12.
- **Internet:** Wymagane jest aktywne połączenie internetowe do pobierania pakietów.
- **Uprawnienia:** Musisz posiadać uprawnienia `sudo`.

## 2. Instalacja
Aby zainstalować oprogramowanie, wykonaj poniższe kroki w terminalu:

1.  Pobierz repozytorium lub przenieś plik `install_packages.sh` na dysk.
2.  Uruchom skrypt instalacyjny za pomocą polecenia:
    ```bash
    sudo bash install_packages.sh
    ```
    > [!NOTE]
    > Skrypt automatycznie poprosi o hasło administratora (sudo), jeśli będzie to wymagane.

## 3. Po instalacji
Gdy skrypt zakończy działanie, należy załadować nowe zmienne środowiskowe (niezbędne m.in. dla pakietu Starlink czy IRAF). Aby zastosować zmiany w bieżącej sesji terminala, uruchom:
```bash
source ~/.bashrc

## 4. Zainstalowane oprogramowanie
Skrypt instaluje i konfiguruje następujące narzędzia:

### Narzędzia graficzne (GUI) i Edytory
- **Stellarium**: Popularne oprogramowanie typu planetarium.
- **DS9 (`saods9`)**: Zaawansowane narzędzie do wyświetlania i analizy obrazów astronomicznych.
- **XEphem (v4.1.0)**: Interaktywny program astronomiczny.
- **VLC**: Odtwarzacz multimedialny.
- **VSCodium**: Otwartoźródłowy edytor kodu (wersja VS Code bez telemetrii).
- **Nano**: Prosty edytor tekstu w terminalu.

### Narzędzia naukowe i biblioteki
- **Python 3**: Wraz z podstawowymi bibliotekami.
- **Phoebe (v1.0.1)**: Oprogramowanie do modelowania układów zaćmieniowych.
- **Starlink (v2021A-REV1)**: Kompleksowy pakiet oprogramowania astronomicznego.
- **IRAF (v2.17)**: Image Reduction and Analysis Facility – standardowe narzędzie do redukcji danych astronomicznych.

## 5. Rozwiązywanie problemów
- **"Command not found"**: Jeśli po instalacji polecenia takie jak `ds9` czy `iraf` nie działają, upewnij się, że wykonałeś polecenie `source ~/.bashrc`.
- **Problemy z grafiką (SSH)**: Jeśli łączysz się zdalnie, pamiętaj o włączeniu przekierowania X11 (`ssh -X user@host`).