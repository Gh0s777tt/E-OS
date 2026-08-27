# Topologia repozytoriów

30 repozytoriów w `repos.toml`, cztery typy o różnych regułach (`CLAUDE.md` §11).
**Kierunek luster ma znaczenie:** GitLab jest źródłem prawdy, a przepisy pobierają
przypięte rewizje z lustra GitHuba.

```mermaid
flowchart LR
    subgraph GL["GitLab — źródło prawdy"]
        META["E-OS<br/>meta / orkiestracja"]
        A["Typ A — komponenty własne<br/>eos-control · eos-sysmon · eos-ui<br/>eos-guard · eos-notes"]
        B["Typ B — vendorowane lustra<br/>eos-redoxfs · eos-ion · eos-coreutils<br/>eos-orbutils · …"]
        C["Typ C — forki z łatkami<br/>eos-kernel · eos-base · eos-relibc<br/>eos-bootloader · eos-userutils"]
        D["Typ D — repozytoria pakietów<br/>eos-pkg-x86_64 · eos-pkg-aarch64"]
    end

    subgraph GH["GitHub — tylko do odczytu"]
        MMIR["E-OS (lustro)"]
        FMIR["forki<br/>bez push-mirrora"]
    end

    META -- "push-mirror<br/>gałąź: sekundy, tag: ~5 min" --> MMIR
    A -. "dwa osobne pushe" .-> FMIR
    B -. "dwa osobne pushe" .-> FMIR
    C -. "dwa osobne pushe" .-> FMIR
    D -- "lustro ZAKAZANE<br/>nadpisałoby publikację" --x GH

    BUILD["cookbook / build obrazu"]
    FMIR -- "pobiera przypiętą rewizję" --> BUILD
    UP["static.redox-os.org<br/>gotowe pakiety upstreamu"] -. "tylko porty firm trzecich" .-> BUILD

    classDef ro fill:#2b2b2b,stroke:#888,color:#ddd;
    class B,D,GH ro;
```

## Co z tego wynika w praktyce

| | |
|---|---|
| **Meta-repo** | push **tylko na GitLab** — ręczny push na GitHuba ściga się z lustrem |
| **Forki (A/B/C)** | **dwa** pushe, każdy zweryfikowany `git ls-remote` przed podbiciem pina (§1.6) |
| **Pakiety (D)** | lustro **zakazane** — `eos-setup-mirrors.sh` pomija `role = "pkg"` (`U-158`) |
| **Kasowanie** | lustro replikuje pushe, **nie kasowania** — usunięcie gałęzi wykonuje się osobno |
