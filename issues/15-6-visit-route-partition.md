# [Processing] 長時間Visitの前後で経路端点を保持する

## Summary

5分以上のCLVisitへ到着する位置点を直前Movementの終点として保持し、滞在中の追加位置点をMovementから除外して、実移動を失わずStay越しのPolylineを防ぐ。

## Background

Issue 15-5による実機再処理でStay越しの1本線は解消したが、20:49→20:59の実移動が消え、Visit内部の20:59→21:04が短いMovementとして残った。現行実装はStay境界のfollowing locationを無条件に次chunkの始点へ送るため、Visit到着直後の点が直前経路から失われ、滞在中の次点と結ばれる。

実機座標はTestへ転記せず、「移動→5分以上のVisit内に複数観測→移動」の時間構造だけを合成Fixtureで再現する。

## Goal

長時間VisitをMovementの停止区間として扱いながら、Visitへ入る最初の観測を直前移動の終点、Visit後の最初の観測を次移動の始点にする。

## Non-Goals

- 5分、150m、90分の閾値変更
- CLVisit自体またはRaw Locationの変更
- 処理Algorithm更新済み日のInvalidation
- UI変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-1-stay-route-boundary.md`
- [x] `issues/15-5-interrupted-day-reprocessing.md`

## Dependencies

- Issue 15-1の5分Stay hard boundary
- Issue 15-5の中断処理再開

## Scope

### Allowed Changes

- `issues/15-6-visit-route-partition.md`
- `docs/processing-rules.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLogTests/Processing/MovementSegmenterTests.swift`

### Forbidden Changes

- SwiftData Schema、Repository、Raw Event、Override
- ProcessingConfigurationの閾値
- UI、Location取得、Signing、外部Package

## Decision

到着・出発が確定し5分以上のCLVisitを長時間Visitとする。Visitへ入った最初のLocationは到着端点として直前chunkへ1回だけ含め、その後Visit内で受信したLocationはMovementへ含めない。Visit後の最初のLocationから新しいchunkを開始する。VisitごとのStay gapは1件だけ生成し、Stayの重複生成を避ける。

## Requirements

1. 5分以上の確定Visitへ入る最初のLocationを直前Movementの終点へ含める。
2. 同じVisit内の2点目以降をMovementから除外する。
3. Visit退出後の最初のLocationから別Movementを開始する。
4. 1つの長時間VisitからStationary Stay gapを重複生成しない。
5. 5分未満またはarrival/departure未確定Visitの既存処理を維持する。
6. 90分GapとlocalDate境界をVisitより優先する。
7. 実機データをFixtureへコピーしない。

## Privacy Requirements

- 座標、経路、IdentifierをLoggerへ出力しない。
- 合成座標だけをTestで使用する。
- 外部通信を追加しない。

## Processing Rules

- `automaticStayDuration = 5分`以上の確定VisitをMovementから除外する停止区間とする。
- 到着端点と出発後始点を直接接続しない。

## Data Model Rules

- 変更なし。

## Acceptance Criteria

- [x] Visit前の実移動が到着地点まで保持される。
- [x] Visit内部のLocation同士をMovementとして保存しない。
- [x] Visit後の移動が独立Segmentになる。
- [x] Stayが重複生成されない。
- [x] 既存境界Testが回帰しない。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Root Cause
- Changed Files
- Tests Added
- Verification
- Deviations
- Unresolved Issues

## Completion

- 長時間Visitへの最初の観測を直前Movementへ残し、Visit内の後続観測を除外し、退出後から新しいMovementを開始するpartitionを実装した。
- Stay gapは同じ確定Visitにつき1件だけ生成する。
- 実機データを転記せず、合成した移動・Visit・再移動で到着端点、内部除外、退出後分割を検証した。5分未満Visitの既存連続性も回帰Testした。
- Simulator Build、395 Unit/Integration Test、13 UI/Launch/Performance Testが成功した。
- SwiftLint strictは0 violation、SwiftFormat lintは0 file、`git diff --check`は成功した。
- 閾値、Schema、Raw Event、Overrideは変更していない。
- 更新前に完了済みの派生データを再生成する仕組みは本IssueのNon-Goalであり、次Issueで処理Algorithm更新のInvalidationを行う。
