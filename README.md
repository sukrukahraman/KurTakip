# Kur Takip

TL bazlı döviz kurlarını gösteren, çevrimdışı da çalışan kur takip uygulaması

## Requirements
- macOS with Xcode 26+ (Swift 6.2), iOS 17.0+ deployment target
- `brew install xcodegen swiftlint swiftformat` (add `fastlane` for local TestFlight uploads)

## Run
```bash
xcodegen generate                         # writes KurTakip.xcodeproj from project.yml (git-ignored)
open KurTakip.xcodeproj           # run the KurTakip-Staging scheme; Production is KurTakip-Production
```

## Configuration
Each environment has an xcconfig in `Config/` (`Staging`, `Production`) and a pair of build configurations. Put your own values
(team ID, certificate pins) in `Config/Secrets.xcconfig` (git-ignored, see `Secrets.example.xcconfig`). In `.xcconfig` files a URL
is written `https:/$()/host/path`, because `//` starts a comment.

## Quality checks
```bash
tools/gate.sh .          # the same script CI runs
tools/gate.sh . App      # one module (a package folder name under Packages/, or App)
```

## Release
Push a `v*` tag. CI builds the `KurTakip-Production` scheme and uploads it to TestFlight with the App Store Connect API key
(secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`, `APPLE_TEAM_ID`).

## Modules
| Module | Purpose |
|---|---|
| `App` | `@main`, composition root, navigation stack, per-environment configuration |
| `CoreCommon` | `AppError`/`AppResult`, `AppLogger`, formatter protocols |
| `CoreModel` | Pure Swift domain models |
| `CoreDesignSystem` | Theme tokens and generic components |
| `CoreUI` | Shared app components (loading, empty, error states) |
| `CoreLocalization` | All user-facing text as String Catalogs, one catalog per feature |
| `CoreTesting` | Test helpers and fakes |
| `Feature*` | One module per feature |

See `docs/SPEC.md` for the features and `docs/audit/` for the latest scorecard.
