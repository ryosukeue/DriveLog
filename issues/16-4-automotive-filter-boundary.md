# [Processing] 車移動フィルタの境界条件を見直す

## Summary

既存の車っぽい移動フィルタを維持したまま、実機で車移動を含む日が表示対象からほぼ全て除外される原因を調査し、分類境界を現実の疎なLocation記録に合わせて調整する。

## Goal

Motionイベントが得られない区間でも、車らしい速度と距離を持つMovement Segmentを過剰に除外せず、徒歩・自転車・判定不能区間は引き続き表示対象へ通さない。

## Required Documents

実装前に次を読むこと。

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`
- [x] `issues/16-1-automotive-movement-filter.md`
- [x] `issues/3-10-movement-classifier.md`
- [x] `issues/14-1-polyline-diagnostics-and-quality.md`

## Dependencies

- `MovementClassifier`
- `ProcessingConfiguration.mvp`
- `AutomotiveMovementFilter`
- `LoadCalendarMonthUseCase`、`LoadDayDetailUseCase`

## Scope

### Allowed Changes

- `issues/16-4-automotive-filter-boundary.md`
- `DriveLog/DriveLog/Processing/Configuration/ProcessingConfiguration.swift`
- `DriveLog/DriveLog/Processing/Classification/MovementClassifier.swift`
- `DriveLog/DriveLogTests/Processing/ProcessingConfigurationTests.swift`
- `DriveLog/DriveLogTests/Processing/MovementClassifierTests.swift`

### Forbidden Changes

- Raw Location、Motion、Visitの保存、削除、書換え
- SwiftData V1 Schema、Migration、Repositoryの永続化形式
- `AutomotiveMovementFilter`の採用条件を`automotiveLike`以外へ拡張すること
- Location Provider、充電Mode、Map描画、UI、外部Package
- 位置情報・経路・PhotoKit Identifierの通常ログ出力
- Signing、Team、Bundle Identifier、Capability

## Investigation

現在のClassifierは、Motionがない場合に「平均速度15 km/h以上」かつ「1つのMovement Segmentが2,000 m以上」の両方を満たすときだけ`automotiveLike`へ分類する。実機のSLCや精度フィルタ後の疎な点列では、車で走行していてもGap・localDate境界・Stay分割によって各Segmentが2,000 m未満になりやすい。一方、日付16日は長いSegmentまたはMotion証拠が残っていた可能性があり、同じ車移動でも日によって採否が偏る。

Repository内には実機のRaw Storeを共有可能なTest Fixtureとして取り込んだものがないため、実データの座標やIdentifierをログへ出さず、既存のSegment生成条件と境界テストから診断する。診断の根拠は速度、距離、Segment点数、分類結果の件数だけに限定する。

## Decision

速度条件は既存の15 km/h以上を維持し、Motionがない場合の距離境界を2,000 mから500 mへ下げる。500 mは既存の最小Segment距離100 mより十分大きく、Mediaの経路関連付け閾値とも一致する。速度条件を同時に要求するため、低速の徒歩・停滞ドリフトをこのFallbackだけで車へ昇格させない。Cycling／Unknownが支配的なMotionは従来どおり`other`とし、automotive／walkingのMotion比率判定も変更しない。

この変更は「全区間を車として残す」ものではなく、疎な記録で分割された短い車区間を保護するための境界調整である。実機での分類精度は、後続の診断ログに記録する件数・速度・距離分布で確認する。

## Requirements

1. MotionなしFallbackは平均速度15 km/h以上かつ距離500 m以上だけを`automotiveLike`とする。
2. 距離499 m以下、速度未満、点数不足、速度算出不能は`automotiveLike`にしない。
3. Cycling／Unknown優勢、Walking優勢のMotion結果を変更しない。
4. `AutomotiveMovementFilter`は引き続き`automotiveLike`だけを表示・集計へ渡す。
5. Raw Event、SwiftData V1、充電中／非充電中のLocation取得方式を変更しない。
6. 境界値、上下の近傍値、Motion優先規則をSwift Testingで確認する。
7. `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`を使用しない。

## Acceptance Criteria

- [ ] 車速度（15 km/h以上）で500 m以上の疎なSegmentが表示対象へ残る。
- [ ] 499 m以下または15 km/h未満のSegmentは除外される。
- [ ] Walking／cycling／unknown区間は従来どおり除外される。
- [ ] 既存のCalendar、Day Detail、Monthly Summary、MapSceneのFilter契約が変わらない。
- [ ] Build、Unit Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。

## Privacy Requirements

- 座標、経路、PhotoKit localIdentifier、写真・動画名をログへ出さない。
- 外部Server、Analytics SDK、追加Packageを導入しない。

## Completion Report Format

### Summary

ClassifierのMotionなしFallback距離境界を見直し、疎な車移動Segmentの過剰除外を抑える。

### Changed Files

- `ProcessingConfiguration.swift`: 車Fallback距離の境界値。
- `MovementClassifier.swift`: 判定ロジックは速度・距離の両条件を維持。
- `ProcessingConfigurationTests.swift` / `MovementClassifierTests.swift`: 境界と既存Motion優先規則。

### Tests Added

500 m、499 m、15 km/h境界、Motion優先規則のSwift Testingを追加・更新する。

### Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

### Manual Verification

実機Raw StoreはRepositoryへ共有されていないため、実走行データでの再現確認は未実施。実機では日付ごとの車移動件数と地図表示を確認する。

### Deviations

Issue 3-10の2,000 m Fallbackは、疎な記録で車区間を過剰除外するため500 mへ変更する。速度条件とMotion優先規則は維持する。

### Unresolved Issues

実機のMotion精度やGPS欠測による分類誤差は、診断情報を確認して追加調整が必要になる可能性がある。
