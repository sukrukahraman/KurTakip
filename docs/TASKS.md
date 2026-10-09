# Tasks
## Stage C — scaffold
- [ ] C1 Preflight
- [ ] C2 Resolve versions
- [ ] C3 Project skeleton + tools
- [ ] C4 Core packages gate
- [ ] C5 Designsystem tokens (brand blue→green finance palette) + components the screens need
- [ ] C6 Common strings (tr, en)
- [ ] C7 CoreNetwork
- [ ] C8 CoreDatabase
- [ ] C9 CoreRepository
- [ ] C12 Scaffold check → commit
## Stage D — features
### D0 app shell (with the first feature)
### FeatureRatesList
- [ ] rates-1 Model: ExchangeRate                         gate: CoreModel
- [ ] rates-2 Remote: RatesDto, RatesAPI                  gate: CoreNetwork
- [ ] rates-3 Local: RateEntity, RateStore                gate: CoreDatabase
- [ ] rates-4 Repository + formatters + fake              gate: CoreRepository CoreTesting
- [ ] rates-6 ViewModel + UiState + mapper + search       gate: FeatureRatesList
- [ ] rates-7 UI: Route, Screen, row, previews, tests     gate: FeatureRatesList
- [ ] rates-8 Visual check (simulator screenshots)
- [ ] rates-9 Navigation wiring                           gate: App
- [ ] rates-10 Strings (tr, en)                           gate: CoreLocalization
- [ ] rates-done Full gate + dead code + auto-commit
### FeatureRateDetail
- [ ] detail-6 ViewModel (converter) + tests              gate: FeatureRateDetail
- [ ] detail-7 UI + tests (KurTakipTextField)             gate: FeatureRateDetail CoreDesignSystem
- [ ] detail-9 Navigation wiring                          gate: App
- [ ] detail-10 Strings (tr, en)                          gate: CoreLocalization
- [ ] detail-done Full gate + auto-commit
## Stage E — hardening & handover
- [ ] E1 Pinning for api.frankfurter.dev (HARD-01)
- [ ] E2 Release build + archive dry run
- [ ] E2b Smoke test (screens, offline, languages, dark, large text)
- [ ] E3 GATE_FINAL
- [ ] E4 /code-review loop
- [ ] E5 Scorecard ≥ 80
- [ ] E7 README, CLAUDE.md
- [ ] E8 Final report
