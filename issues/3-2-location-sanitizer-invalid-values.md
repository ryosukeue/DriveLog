# [Processing] LocationSanitizerの無効座標除外を実装する

## Summary

位置イベントを決定的な時系列へ整列し、範囲外・非有限座標、無効精度、無効・過度な未来時刻を後続処理から除外する。

## Goal

生ログを変更せず、受理点と除外理由付きの点を返す`LocationSanitizer`の基礎を実装する。

## Non-Goals

- 30秒・10mの重複除外
- 500m超の低精度点除外
- 250km/h超の座標ジャンプ除外

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1 LocationEventData
- Issue 3-1 ProcessingConfiguration
- Issue 0-5 Clock

## Scope

### Allowed Changes

- `issues/3-2-location-sanitizer-invalid-values.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLog/Domain/Entities/LocationEventData.swift`
- `DriveLog/DriveLog/Shared/Time/Clock.swift`
- `DriveLog/DriveLog/Shared/Time/SystemClock.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`

### Forbidden Changes

- `LocationEventData`以外のDomain型、Repository、SwiftData Schema、Provider、UI
- Project設定、外部Package

## Requirements

1. `LocationSanitizing`を設計どおりの`Sendable` Protocolとして定義する。
2. `SanitizedLocations`はacceptedとrejectedを保持する`Sendable, Equatable`値型とする。
3. `RejectedLocation`は元の`LocationEventData`と`RejectedLocationReason`を保持する。
4. `RejectedLocationReason`は設計済み7 caseだけを持つ。
5. 入力をtimestamp昇順、同時刻ならhorizontalAccuracy、createdAtの優先順で決定的に整列する。
6. 緯度`-90...90`、経度`-180...180`の範囲外または非有限値を`invalidCoordinate`で除外する。
7. 負または非有限のhorizontalAccuracyを`invalidAccuracy`で除外する。
8. 非有限のtimestampまたは`Clock.now`より24時間以上未来のtimestampを`futureTimestamp`で除外する。
9. `Clock.now`はsanitizeごとに1回取得し、全入力へ同じ基準時刻を使う。
10. 境界値の緯度・経度と24時間未満の未来時刻は受理する。
11. 元の入力配列とイベントを変更しない。
12. 純粋Processingから利用する`Clock`、`SystemClock`、`LocationEventData`を明示的`nonisolated`とし、振る舞いと保存形式は変更しない。

## Acceptance Criteria

- [x] Protocol、結果型、全7除外理由が定義される。
- [x] 範囲外、NaN／Infinity座標、負／非有限精度が正しい理由で除外される。
- [x] 24時間以上未来と非有限時刻が除外される。
- [x] 受理点と除外点が決定的な時系列順で返る。
- [x] 空、1件、全件除外を正常結果として扱う。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decisions

- Domainの`LocationEventData`は設計上の`id`を公開していないため、timestamp、精度、createdAtが同一の場合は元入力indexを最終tie-breakerとする。同一入力に対する決定性を維持し、Domain公開APIはこのIssueで変更しない。
- `Date`の内部秒値がNaN／Infinityの場合は時系列比較不能なため`futureTimestamp`へ分類する。
- 24時間「以上」を除外する文言を採用し、ちょうど24時間も除外する。
- TargetのMainActor既定値による新規Warningを避け、ProcessingをMainActor外で実行可能にするため、依存する既存の純粋型に隔離注釈を追加する。

## Interface Contract

```swift
protocol LocationSanitizing: Sendable {
    func sanitize(_ locations: [LocationEventData]) -> SanitizedLocations
}
```

## Test Requirements

### Unit Tests

- [x] 緯度・経度の上下境界、範囲外、NaN、Infinity。
- [x] 精度0、負、NaN、Infinity。
- [x] 24時間未満、ちょうど24時間、24時間超、非有限時刻。
- [x] 時系列外入力と同時刻tie-breaker。
- [x] 空、1件、全件除外、入力不変。

### Integration Tests

- なし。

### UI Tests

- なし。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/3-2-location-sanitizer-invalid-values.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLog/Domain/Entities/LocationEventData.swift`
- `DriveLog/DriveLog/Shared/Time/Clock.swift`
- `DriveLog/DriveLog/Shared/Time/SystemClock.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`

## Definition of Done

- [x] GoalとAcceptance Criteriaを満たす。
- [x] Allowed Changes内だけを変更する。
- [x] 全検証が成功する。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Diff Check:
### Manual Verification
### Deviations
### Unresolved Issues
