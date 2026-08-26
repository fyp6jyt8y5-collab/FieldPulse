# FieldPulse

Application SwiftUI iOS + watchOS avec localisation Core Location, meteo WeatherKit, Watch Connectivity et complications WidgetKit.

## Generation et compilation

Windows ne fournit pas Xcode ni les SDK Apple. Sur macOS 14+ :

```bash
brew install xcodegen
xcodegen generate
open FieldPulse.xcodeproj
```

Dans Xcode, renseignez votre Team dans Signing & Capabilities, activez WeatherKit pour les trois cibles, puis activez les identifiants iCloud/Watch Connectivity selon votre compte. Les profils doivent couvrir l’app iOS, l’app Watch et l’extension Widget.

Si vous changez `PRODUCT_BUNDLE_IDENTIFIER_PREFIX`, remplacez aussi `group.com.example.fieldpulse` dans les trois fichiers entitlements et dans `Shared/SharedDataStore.swift`, puis enregistrez exactement cet App Group dans le portail Apple.

Le projet demande uniquement la localisation au premier plan (`NSLocationWhenInUseUsageDescription`). WeatherKit peut exiger l’activation du service dans Certificates, Identifiers & Profiles et les conditions Apple applicables.

## GitHub Actions

Le workflow `.github/workflows/build.yml` installe XcodeGen et genere le projet sur le runner macOS. Le job `build-check` compile sans signature, donc il fonctionne des le premier push. Pour produire une IPA installable, ajoutez la variable GitHub `ENABLE_SIGNED_BUILD=true`, puis configurez ces secrets : `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `IOS_PROFILE_BASE64`, `WATCH_PROFILE_BASE64`, `EXPORT_OPTIONS_BASE64`, `APPLE_TEAM_ID`. Ajoutez aussi `PRODUCT_BUNDLE_IDENTIFIER_PREFIX` (par exemple `com.votreentreprise`).

Generez `ExportOptions.plist` sur un Mac pour le mode choisi (`development`, `ad-hoc` ou `app-store`) et encodez-le en base64. Ne committez jamais le certificat, le mot de passe, les profils ou ce plist.

L’IPA se telecharge dans GitHub Actions > workflow run > Artifacts. Pour TestFlight, utilisez `app-store` et envoyez ensuite l’IPA avec Transporter ou une etape App Store Connect authentifiee. Sans certificat/profil Apple, aucune GitHub Action ne peut fabriquer une IPA installable : Apple exige une signature cryptographique liée à ton équipe.

Depuis Windows, crée un dépôt GitHub, téléverse ce dossier, ouvre l’onglet Actions et lance `Build FieldPulse`. Le runner macOS de GitHub exécute Xcode ; tu n’as pas besoin de posséder un Mac.
