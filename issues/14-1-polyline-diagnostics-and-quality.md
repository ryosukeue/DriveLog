# [Location] Polylineの診断情報を追加し不要な分断を減らす

## Summary

Raw Locationの取得からMKPolyline描画までの件数・除外理由・境界理由を座標なしで診断可能にし、位置点が連続する移動経路をStayやMotionイベントだけで分断しないようにする。

## Background

実機ではPolylineが粗く途中で切れる。監査の結果、Productionの取得はSignificant Location Changeのみで点が疎である。一方、処理は位置点間にVisitが重なる、または3分以上のMotion遷移があるだけで区間を分割し、100m未満または2点未満の断片を破棄する。この組合せは、位置点が存在する経路も欠落させる。

`maximumContinuousGap = 90分`は大きな欠損を接続しない境界として機能しており、短縮すると疎なSLCデータをさらに分断するため本Issueでは維持する。`simplificationTolerance = 30m`は10点以上にだけ適用され、現在の疎な経路の直接原因ではない。ただし入力・出力点数を診断対象にする。Mediaの500m閾値はMovementとの関連付けだけに使われ、Annotation除外条件ではない。

## Goal

座標や識別子を記録せずPolyline生成の各段階を診断でき、localDate境界または90分以上の実データ欠損だけで経路が分割される状態にする。

## Non-Goals

- 充電中高精度Location取得
- MapKitの描画方式変更
- SwiftData V1 Schema変更
- 実機データのFixture化

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- MVP Phase 5 Processing Pipeline

## Scope

### Allowed Changes

- `issues/14-1-polyline-diagnostics-and-quality.md`
- `DriveLog/DriveLog/Processing/Location/`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLog/Processing/Pipeline/DefaultDayProcessor.swift`
- `DriveLog/DriveLog/Processing/Route/RouteSimplifier.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLogTests/Processing/`
- `DriveLog/DriveLogTests/Shared/Logging/`
- `docs/processing-rules.md`
- `docs/test-plan.md`
- `docs/implementation-plan.md`

### Forbidden Changes

- Location取得Mode
- SwiftData SchemaとRepository
- UI、MapKit、PhotoKit
- Signing、Team、Bundle Identifier、Capability
- 外部Package

## Requirements

1. Raw入力数、sanitize採用数、理由別reject数、位置点間隔分布、accuracy分布を座標なしで集計する。
2. localDate境界、連続Gap、最終Segment数、破棄数、簡略化前後点数を診断できる。
3. VisitとMotion遷移はStay判定・分類の証拠として維持するが、Movement Polylineの分割境界にはしない。
4. localDate境界と90分以上のGapは分割を維持する。
5. 30m簡略化と永続化形式は本Issueで変更しない。
6. ログへ緯度、経度、経路、PhotoKit identifierを含めない。
7. 実機データをTest Fixtureへコピーしない。

## State Changes

- SwiftData変更なし。
- Processing結果へPrivacy安全な診断値を追加する。

## Privacy Requirements

- 件数、時間間隔bucket、accuracy bucket、固定reasonだけを診断対象にする。
- 正確な時刻、座標、経路、メディア識別子をログへ出さない。

## Processing Rules

- Hard boundary: localDateKey変更、位置点間隔90分以上。
- Visit/Motion transition: 分割せず後続のStay/Classification処理で利用する。
- Route simplification: 10点以上、30m toleranceを維持し入出力点数を計測する。

## Tests

- [ ] reason別sanitize件数とaccuracy/interval分布
- [ ] Visitが経路を分断しない
- [ ] Motion遷移が経路を分断しない
- [ ] localDate境界と90分Gapは分断する
- [ ] 診断値に座標・識別子・自由文字列がない
- [ ] Build/Test/Lint/Format/diff check

## Acceptance Criteria

- 位置点が存在する同一日・90分未満の経路はVisit/Motionだけで切れない。
- 大きな欠損と日付境界は直線接続されない。
- Pipeline各段階の件数と除外理由をPrivacy安全に確認できる。
- 全自動検証が成功し、新規Warningと仕様外変更がない。

## Decisions / Deviations

- 90分Gapと30m simplificationは実機症状の直接原因と断定できないため維持する。
- 取得頻度そのものは次Issueの充電中Modeで改善する。

## Completion Report Format

- Summary
- Root cause and evidence
- Changed files and reasons
- Tests added
- Build/Test/SwiftLint/SwiftFormat/diff results
- Manual verification
- Deviations
- Unresolved issues

## Completion

- Visit/Motion境界をStay/Classificationの診断証拠として保持しつつ、Movement座標列の分割には使用しない実装へ変更した。
- 位置点のaccuracy・時間間隔は固定bucket、除外は固定reason、Pipelineは各段階の件数だけを保持する。座標・正確な時刻・識別子は診断値に含めない。
- `maximumContinuousGap = 90分`、`simplificationTolerance = 30m`、SwiftData V1永続化形式は維持した。
- Build: 成功。
- Test: Swift Testing 383件、UI Test 13件、すべて成功。
- SwiftLint / SwiftFormat / `git diff --check`: 成功。
- Warning: Xcode/AppIntents metadata、Simulator CoreLocation Main Thread Checker、Simulator RuntimeのAccessibility class重複。新規Source warningなし。
- Manual: SimulatorのUI TestでPolyline/Map遷移を確認。実機データでの点数分布と表示品質は未確認。
