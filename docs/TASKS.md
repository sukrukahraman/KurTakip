# Tasks
## Stage C — scaffold
- [x] C1 Preflight
- [x] C2 Resolve versions
- [x] C3 Project skeleton + tools
- [x] C4 Core packages gate
- [x] C5 Designsystem tokens (brand blue→green finance palette) + components the screens need
- [x] C6 Common strings (tr, en)
- [x] C7 CoreNetwork
- [x] C8 CoreDatabase
- [x] C9 CoreRepository
- [x] C12 Scaffold check → commit
## Stage D — features
### D0 app shell (with the first feature)
### FeatureRatesList
- [x] rates-1 Model: ExchangeRate                         gate: CoreModel
- [x] rates-2 Remote: RatesDto, RatesAPI                  gate: CoreNetwork
- [x] rates-3 Local: RateEntity, RateStore                gate: CoreDatabase
- [x] rates-4 Repository + formatters + fake              gate: CoreRepository CoreTesting
- [x] rates-6 ViewModel + UiState + mapper + search       gate: FeatureRatesList
- [x] rates-7 UI: Route, Screen, row, previews, tests     gate: FeatureRatesList
- [x] rates-8 Visual check (simulator screenshots)
- [x] rates-9 Navigation wiring                           gate: App
- [x] rates-10 Strings (tr, en)                           gate: CoreLocalization
- [x] rates-done Full gate + dead code + auto-commit
### FeatureRateDetail
- [x] detail-6 ViewModel (converter) + tests              gate: FeatureRateDetail
- [x] detail-7 UI + tests (KurTakipTextField)             gate: FeatureRateDetail CoreDesignSystem
- [x] detail-9 Navigation wiring                          gate: App
- [x] detail-10 Strings (tr, en)                          gate: CoreLocalization
- [x] detail-done Full gate + auto-commit
## Stage E — hardening & handover
- [ ] E1 Pinning for api.frankfurter.dev (HARD-01)
- [ ] E2 Release build + archive dry run
- [ ] E2b Smoke test (screens, offline, languages, dark, large text)
- [ ] E3 GATE_FINAL
- [ ] E4 /code-review loop
- [ ] E5 Scorecard ≥ 80
- [ ] E7 README, CLAUDE.md
- [ ] E8 Final report
