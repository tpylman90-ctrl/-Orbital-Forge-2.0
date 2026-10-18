# Android signing — Orbital Forge 2.0

## One-time GitHub setup
Open **Settings → Secrets and variables → Actions → New repository secret** in this repository and create these **four** secrets. Their exact values are in the privately generated file `GITHUB_ACTIONS_SECRETS.txt` provided outside GitHub:

- `ANDROID_KEY_ALIAS` — key alias (the signing username).
- `ANDROID_KEYSTORE_PASSWORD` — password to open the JKS keystore.
- `ANDROID_KEY_PASSWORD` — distinct password protecting the key entry.
- `ANDROID_KEYSTORE_BASE64` — single-line Base64-encoded JKS bytes.

Keep the original `orbital-forge-2-release.jks` and recovery text in separate secure backups. **Never commit these to GitHub**, attach them to an issue, or include them in a release asset.

## Signed releases
`Actions → Signed Android release APK → Run workflow`. On push to main, the same workflow will run automatically. Until all four secrets are configured, the release workflow intentionally fails with a missing-secret message; it never creates a new signing identity.

The job exports an unsigned Android release build, runs zipalign, signs using Android `apksigner` with **both passwords**, verifies the APK signature, and uploads only the signed APK as an artifact.

The app package is `com.orbitalforge.two`. Keep this package ID and the signing identity unchanged for future updates. Increment Android `version/code` with releases.

## Base64 recovery (optional)
```sh
base64 -w 0 orbital-forge-2-release.jks
```
Never print the Base64 or passwords in GitHub Actions logs.

## Security
JKS passwords and Base64 are **credentials**, not project configuration. Base64 is encoding, *not encryption*. Anyone with the Base64 plus credentials could sign an APK as this app. If credentials or key have been disclosed, rotate before public release.
