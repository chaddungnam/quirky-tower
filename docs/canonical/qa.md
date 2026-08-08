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
- main scene, 공통 UI, 통합 도전 씬 계약, 자동 15층 상태 흐름: PASS
- 고정 시드 424242: 15층 완주, 스토리 3비트, 광고/결제 동등성, 체크포인트 복원 PASS
- 10,000런: 불가능 상태 0, 광고/결제 불일치 0
- 파일 크기와 core 의존성 검사: PASS
- 통합 도전 회귀 테스트: 세 경로, 경로 버튼 대비, 회피·파괴 상태, 정규화 입력, ×1.50 전달 PASS
- Godot MCP macOS 런타임: 방송사고 경로 버튼, 직접 마우스 드래그, 타이밍 탭, PERFECT 피드백, ×1.50 점수, 결과 버튼, 2층 진입 PASS
- 결과 버튼 회귀 테스트: 신호 처리 중 locked object 크래시 재현 후 수정 PASS
- 앱 셸 회귀 테스트: 시작 배너, 홈, 설정, 10개 언어와 취소, 독일어 실시간 전환, 홈 복귀, 플레이 진입 PASS
- 선택 팝업 회귀 테스트: 세로 VBox, 세로 스크롤, 긴 독일어 줄바꿈, 96px 터치 높이 PASS
- 런 재시작 정리 회귀 테스트: 활성 도전 1개와 안정적인 `TowerTrial` 씬 이름 PASS
- Godot MCP 360×640 런타임: 시작 배너, 한국어 홈·설정, 언어 세로 스크롤, 독일어 장문 설정, 홈 복귀, 인게임 진입 PASS
- 현재 검증 구간 런타임 오류: 0

## 아직 증명하지 않은 것

사용자 입력만으로 15층 전체를 완주하거나 게임오버·재시작하는 흐름은 아직 검증하지 않았다. 설정 토글은 실제 오디오·햅틱에 연결되지 않고 저장되지 않는다. macOS 마우스와 자동 흐름 검증은 재미, 실제 손가락 손맛, Android/iOS 안전 영역, 햅틱, 오디오, 네이티브 광고, 스토어 결제, Supabase, 실제 친구·랭킹 네트워크를 증명하지 않는다.

출시 export 전에는 `godot_mcp` 플러그인을 비활성화해 개발용 MCP autoload 2개가 제거됐는지 확인한다.
