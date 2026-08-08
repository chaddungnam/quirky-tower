# QA

## 전체 검사

```bash
bash scripts_dev/qa/check_project.sh
for test_file in scripts_dev/qa/headless/*_test.gd; do
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "$test_file"
done
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/run_smoke.gd -- --seed=424242
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/run_balance.gd -- --runs=10000
```

밸런스 보고서는 `qa_output/headless_balance.json`에 생성되며 Git에는 넣지 않는다.

## 현재 증거

- catalog, challenge rules, run engine: PASS
- 고정 시드 424242: 15층 완주, 스토리 3비트, 광고/결제 동등성, 체크포인트 복원 PASS
- 10,000런: 불가능 상태 0, 광고/결제 불일치 0
- 파일 크기와 core 의존성 검사: PASS

## 아직 증명하지 않은 것

헤드리스 결과는 실제 손가락 입력, 화면 연출, Android/iOS 안전 영역, 햅틱, 네이티브 광고, 스토어 결제, Supabase, 실제 친구·랭킹 네트워크를 증명하지 않는다.
