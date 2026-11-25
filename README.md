# ClipSaver

[![Release](https://github.com/joaodforce/ClipSaver/actions/workflows/release.yml/badge.svg)](https://github.com/joaodforce/ClipSaver/releases)

<p align="center"><img src="Artwork/Icon.svg" width="128" alt="ClipSaver icon"></p>

Save shared files to any folder, straight from the macOS share sheet.

ClipSaver exists because **Home.app's clip sharing has no "save to disk"** — sharing a camera recording only offers the standard share sheet (AirDrop, Mail, Messages…) with no way to dump the file where you actually want it. ClipSaver adds a **"Save Clip to Folder"** action to that sheet: pick a folder, get your `.mp4`.

## How it works

- A tiny container app (`ClipSaver.app`) carries a `com.apple.share-services` extension
- On share, the extension stages the item(s) via `NSItemProvider.loadFileRepresentation` (prefers audiovisual types, falls back to whatever was shared)
- An `NSOpenPanel` sheet asks for a destination — remembered for next time
- Files are copied there, keeping the sender's filename (e.g. Home's `Camera-Name_YYYY-MM-DD_HH-MM-SS.mp4`)

## Install

### Prebuilt

Grab `ClipSaver-*.zip` from [Releases](https://github.com/joaodforce/ClipSaver/releases), unzip, move `ClipSaver.app` to `/Applications`, then:

```bash
xattr -dr com.apple.quarantine /Applications/ClipSaver.app
pluginkit -a /Applications/ClipSaver.app/Contents/PlugIns/ClipSaverShare.appex
open /Applications/ClipSaver.app   # launch once to register the extension
```

> The app is ad-hoc signed, so macOS will report it as "damaged" until
> quarantine is stripped — the `xattr` line above does that.

### From source

Requirements: Xcode + [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

```bash
git clone https://github.com/joaodforce/ClipSaver.git
cd ClipSaver
./build.sh
cp -R .build/Build/Products/Release/ClipSaver.app /Applications/
pluginkit -a /Applications/ClipSaver.app/Contents/PlugIns/ClipSaverShare.appex
open /Applications/ClipSaver.app   # launch once to register the extension
```

### If it doesn't show in the share sheet

- Share sheet → **Edit Extensions…** → enable ClipSaver, or
- System Settings → General → Login Items & Extensions → **Sharing**
- Then quit and reopen the app you're sharing from — the menu is cached aggressively

## Usage

1. In Home.app, right-click a recording → **Share…**
2. Choose **ClipSaver** ("Save Clip to Folder")
3. Pick a folder — the clip is copied there

## Hacking

| Path | Purpose |
|---|---|
| `project.yml` | XcodeGen spec — `build.sh` regenerates the `.xcodeproj` |
| `Sources/ClipSaverShare/ShareViewController.swift` | All the extension logic |
| `Sources/ClipSaver/ClipSaverApp.swift` | Container app / instructions UI |
| `Artwork/Icon.svg` | Icon source |
| `make_icon.sh` | Rasterizes the SVG → `AppIcon.icns` (Swift + `NSImage` + `iconutil`, no external deps) |

### Notes

- `NSExtensionActivationRule` is `TRUEPREDICATE`, so the action is offered for *any* shared item — tighten it to `public.movie`/`public.data` subqueries if that's too noisy.
- Both targets are sandboxed; the extension holds `com.apple.security.files.user-selected.read-write`, so the open panel grants write access wherever you pick.
- Signed ad-hoc (`CODE_SIGN_IDENTITY="-"`), which is fine for local use. Swap in a Developer ID if you want to distribute it.

## Troubleshooting

```bash
pluginkit -mA | grep -i clipsaver            # is the extension registered?
pluginkit -e use -i com.jed.clipsaver.share  # force-enable it
```

If the share sheet still ignores it, restart the host app — or log out/in.

## License

[MIT](LICENSE)
