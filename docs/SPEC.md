# Kur Takip — Specification
Bundle id: com.example.kurtakip · App prefix: KurTakip · iOS 17.0+ · iPhone · Xcode 26 / Swift 6.2
Languages: tr (default), en · Design source: none (text wireframes) · API: https://api.frankfurter.dev/v1/

## Summary
Türkiye'deki kullanıcılar için TL bazlı döviz kurlarını gösteren, internet olmadığında son kaydedilen kurları sunan basit bir kur takip uygulaması. Bir kura dokununca kur ve küçük bir çevirici açılır.

## Features
| Feature package | Purpose | Screens |
|---|---|---|
| FeatureRatesList | TL bazlı kur listesi, arama, çek-yenile, çevrimdışı önbellek | RatesList |
| FeatureRateDetail | seçilen kurun değeri ve TL → döviz çevirici | RateDetail |

## Screens
### RatesList  (FeatureRatesList · wireframe below)
```
[ Kurlar                         ]  large navigation title
[ 🔍 Ara                         ]  searchable (code or localized name)
[ 31 kur                         ]  section header (plural)
[ USD  ABD Doları       49,21 ₺ ]  row: code, name, 1 unit in TRY
[ EUR  Euro             55,07 ₺ ]
[ Son güncelleme: 8 Eki 2026     ]  footer text
```
- States: loading · content · empty (no cache, refresh ok) · search-empty · error(retry) · refresh-error(banner, cache stays)
- Actions: tap row → RateDetail(code); pull down → refresh
- Components: KurTakipBanner, RateListItem, EmptyState, ErrorState, LoadingState
- Strings (ratelist.xcstrings): ratelist_title, ratelist_search_prompt, ratelist_count (plural), ratelist_updated %@, ratelist_empty, ratelist_search_empty, ratelist_refresh_failed

### RateDetail  (FeatureRateDetail)
```
[ < Kurlar        USD            ]
[ ABD Doları                     ]
[ 1 USD = 49,21 ₺                ]
[ 1 ₺ = 0,0203 USD               ]
[ Tutar (₺)  [ 1000          ]   ]  KurTakipTextField
[ = 20,32 USD                    ]
```
- States: loading · content · notFound (rate removed) · error
- Strings (ratedetail.xcstrings): ratedetail_title, ratedetail_amount_label, ratedetail_not_found, ratedetail_result %@

## Data
- Models: ExchangeRate(code, tryPerUnit: Double, quotedOn: Date)  (API returns units-per-1-TRY; the repository inverts it)
- API: GET /latest?base=TRY → RatesDto { base, date "yyyy-MM-dd", rates: [code: Double] }
- Local: SwiftData RateEntity (offline cache, schema V1) · Keychain: none · UserDefaults: none
- Repositories: RatesRepository(observeRates, refresh)
- Formatting: currency names from Locale (no second API call); numbers/dates through injectable formatters (I18N-11)

## Navigation
RatesList (root) → RateDetailKey(code) → back

## Environments
| Configuration | Bundle id | API base URL | Link host |
|---|---|---|---|
| Staging | com.example.kurtakip.stage | https://api.frankfurter.dev/v1/ | stage.kurtakip.example.com |
| Production | com.example.kurtakip | https://api.frankfurter.dev/v1/ | kurtakip.example.com |
(There is no separate staging API; both point at the public one. Link hosts are unused: no universal links.)

## Integrations
| Integration | Provider | Module | Why |
|---|---|---|---|
| none | — | — | the description needs no analytics, push or remote config |
Always on: AppLogger, Main Thread Checker, Router.

## Optional packages
none.

## Hardening
| # | Item | Applies | How / why N/A |
|---|---|---|---|
| 1 | Pinning | yes | Production only (Staging stays unpinned). SPKI pins in Config/Production.xcconfig `API_CERT_PINS`, read 2026-10-09 with `openssl s_client` from api.frankfurter.dev:443 (leaf CN=frankfurter.dev, issuer GTS WE1; chain verified OK): intermediate **GTS WE1** `sha256/kIdp6NNEd8wsugYyyIYFsi1ylMCED3hZbSR8ZFsa/A4=`, root **GTS Root R4** `sha256/mEflZT5enoR1FuXLgYYGqnVEoZvmf9c2bVBpiOjYQ0c=` (identical to the macOS system-store certificate). Backup roots from the macOS system trust store (`security find-certificate -c`): GTS Root R1 `sha256/hxqRlPTu1bMS/0DITB1SSu0vd4u/8l8TjPgfaAp63Gc=`, ISRG Root X1 `sha256/C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=`, GlobalSign Root CA `sha256/K87oWBWM9UZfyddvDfoxL+8lpNyoUB2ptGtn0fv6G2Q=`. The leaf is not pinned (rotates ~90 days: current one expires 2026-12-20). **To be confirmed by the user.** |
| 2 | Encryption at rest | N/A | no tokens or personal data are stored |
| 3 | Release hardening | yes | template Release settings |
| 4 | App Attest | N/A | no sensitive data |
| 5 | Capture protection | N/A | no sensitive screens |
| 6 | Biometric | N/A | no login |
| 7 | Signing secrets | yes | none in repo; CI uses the App Store Connect API key |
| 8 | Dependency scan | yes | dependency-scan.yml + dependabot |
Sensitive-app defaults (SEC-07): no.

## Privacy
| Item | Decision |
|---|---|
| Required-reason APIs used | none in app code (verified by check_rules PRIV-01) |
| Permission strings (localized) | none |
| Tracking (ATT) | no; NSPrivacyTracking = false |
| Account creation / third-party login | none |

## Version notes
none.

## Known exceptions
- No `rules-ignore` or lint suppressions are used.
- Intermittent test-process crash (4 of ~35 runs while building the project): `EXC_BAD_ACCESS` in Core Data `_generateTriggerSQL` while a CoreDatabase test opens an in-memory container; the cause is not proven. `AppDatabase` serializes container creation as a mitigation (unverified). If the gate shows "the test process crashed", re-run once and keep the crash report.
