# DriveLog 実機確認Checklist

Simulatorでは保証できない項目をRelease候補を入れたiPhoneで確認する。

## Location / Battery

- [ ] 非充電時はSignificant Location Change監視だけになり、常時GPS表示にならない
- [ ] 充電開始後に高精度Modeへ移り、同一Providerから概ね1分以上の間隔でRaw Locationが増える
- [ ] 充電終了後に低電力Modeへ戻る
- [ ] 画面消灯・Backgroundの車載走行で、OSが許す範囲の記録が継続する
- [ ] Force Quit後の高精度再開を期待しないことを確認する
- [ ] 30分以上の走行で発熱とBattery状態を確認する

## Polyline

- [ ] Raw取得/保存件数、精度bucket、reject/duplicate/gap理由を座標なしで確認する
- [ ] 位置点がある通常走行で不要なPolyline分断がない
- [ ] 90分以上の欠損や日付境界を直線で接続しない
- [ ] 30m簡略化後も道路形状の主要な曲がりが残る
- [ ] 長い日のFull MapでMemory warningや操作停止がない

## Photos / Videos

- [ ] Full Photo権限とLimited権限の双方で選択済みMediaがGridへ出る
- [ ] 位置情報付き写真/動画が地図へ出る
- [ ] 位置情報なしMediaはGridだけに出る
- [ ] 写真は角丸Thumbnail、動画は再生Icon、重なりはClusterになる
- [ ] iCloud上のみ/取得失敗Mediaでもfallback Annotationが残る
- [ ] Annotation tapから写真/動画Previewへ遷移する

## Stay / Existing Data

- [ ] 「滞在として確定」「非表示」「自動判定へ戻す」が即時反映される
- [ ] 再処理後もStay Overrideが対象へ再接続される
- [ ] 保存済み分類Overrideは表示へ反映されるが、新規分類変更UIは存在しない
- [ ] 既存V1 StoreがMigration要求やデータ消失なしで開く

## Calendar / Layout / Accessibility

- [ ] 現在月付近から始まり、上下Scrollで過去/未来月が遅延追加される
- [ ] 横Swipeで月送りしない
- [ ] 記録なし日はDay Detailへ遷移しない
- [ ] iPhone SEとPro Max、Light/Dark、最大Dynamic Typeで破綻しない
- [ ] VoiceOverで月見出し、日付、距離、Media、Stay操作、保存中状態を理解できる
- [ ] Reduce Motionで不要な独自Animationがない
- [ ] Portrait固定で回転してもLandscapeにならない

## Privacy / Deletion

- [ ] Console logに緯度、経度、経路、PhotoKit identifier、Media filenameが出ない
- [ ] 日付削除でRaw/Derived/Override/Media Cacheが消え、Photos Asset本体は残る
