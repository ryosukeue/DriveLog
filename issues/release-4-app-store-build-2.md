# [Release] Map操作修正版をApp Storeへ提出する

## Summary

Map操作安定化を含む現在の`main`をVersion 1.1 Build 2としてArchive／Uploadし、実機Screenshotを6.9-inch用へ安全に整えてApp Store Connectへ登録し、審査へ提出する。

## Background

Version 1.0はApp Storeで承認済みだが、最新のMap Gesture修正を含んでいない。Downloads内の実機Screenshotは1179×2556の6.3-inch形式で、Dynamic Islandに再生中の音楽情報が表示されている。

## Goal

アプリ画面を改変せず音楽情報だけを除去したScreenshotと、最新SourceのBuild 2を使用してVersion 1.1を審査提出する。

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `issues/13-16-release-build.md`
- [x] `issues/13-17-mvp-check-list.md`
- [x] `issues/release-2-app-store-signature.md`
- [x] `issues/release-3-app-icon.md`
- [x] `issues/18-5-map-gesture-selection-stability.md`

## Scope

### Allowed Changes

- `issues/release-4-app-store-build-2.md`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- App Store ConnectのVersion 1.1 Metadata、Screenshot、Build選択、審査提出
- Workspace外の一時Archive／Export／Screenshot成果物

### Forbidden Changes

- Swift Source、Test、Asset Catalog
- Signing方式、Development Team、Bundle Identifier、Capability
- Deployment Target、Target、Scheme、Build Configuration
- SwiftData Schema、Location／Processing／UIロジック
- 外部Package

## Requirements

1. App Store ConnectがVersion 1.0を承認済みのため、`MARKETING_VERSION`を`1.1`へ更新する。
2. App Targetの`CURRENT_PROJECT_VERSION`を`2`へ更新する。
3. 1179×2556の3枚を、比率を維持して6.9-inch対応の1290×2796へ変換する。
4. Dynamic Island内部のAlbum Art／再生Indicatorだけを黒で除去し、アプリUI、地図、文字、写真、Status Barの他要素を変更しない。
5. ScreenshotをRGB、不透明PNGとして出力する。
6. Build、全Test、Lint、Format、Diff Checkを成功させる。
7. Release Archive、App Store Connect Export、厳格な署名検証を成功させる。
8. Build 2をApp Store ConnectへUploadする。
9. 3枚のScreenshotを日本語のiPhone 6.9-inch枠へ順番どおり登録する。
10. Version 1.1へBuild 2を選択し、必要Metadataを満たして審査へ提出する。

## Acceptance Criteria

- [x] 3枚のScreenshotが1290×2796、不透明PNGである。
- [x] 音楽情報がなく、アプリ画面の内容が保持されている。
- [x] Version 1.1 Build 2の全検証が成功する。
- [x] App Store Connect Uploadが成功する。
- [ ] Screenshot登録とBuild 2選択が成功する。
- [ ] Version 1.1が審査提出済みになる。
- [ ] GitHubとNASの`main`へRelease変更が反映される。

## Completion Report Format

- Summary
- Screenshot Processing
- Version and Build
- Verification
- App Store Connect
- Git
- Deviations
- Unresolved Issues
