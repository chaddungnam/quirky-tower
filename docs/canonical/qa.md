# QA

공통 테스트 구조와 실행 게이트는 [`house_duck_test_case_standard.md`](house_duck_test_case_standard.md)를 따른다. 기능 완료 전 Feature/Risk, 마일스톤 전 BAT/BVT와 핵심 루프, 출시 전 Device까지 실행한다.

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

## 프로젝트 로컬 게이트

| TC ID | 분류·우선순위 | 행동과 기대결과 | 자동화·증거 | 결과 |
|---|---|---|---|---|
| QT-BAT-001 | BAT P0 | 프로젝트를 파싱하고 메인 씬이 세로 FHD+ 설정으로 기동한다. | `check_project.sh`, `main_scene_test.gd` | Pass |
| QT-BVT-001 | BVT P1 | 배너→홈→설정→언어 팝업을 돌고, 뒤로가기는 팝업과 설정을 한 층씩 닫는다. | `app_shell_test.gd`, Godot MCP `ui_cancel` | Pass |
| QT-RISK-001 | Risk P1 | 선택 버튼을 반복 입력해도 콜백과 상태 전이는 한 번만 실행된다. | `ui_foundation_test.gd` | Pass |
| QT-CORE-001 | Feature P0 | 세 도전을 포함한 15층과 스토리 3비트를 완주한다. | `playable_loop_test.gd`, `run_smoke.gd --seed=424242` | Pass |
| QT-DATA-001 | Data P1 | 카탈로그 참조와 10,000런에서 불가능 상태·광고/유료 Boost 차이가 없다. | `catalog_test.gd`, `run_balance.gd --runs=10000` | Pass |
| QT-VIS-001 | Visual P1 | GUI 내장 9:20에서 한국어 홈, 독일어 장문, 아랍어 RTL이 잘리거나 겹치지 않는다. | Godot MCP 691×1537 캡처 검수, 오류 0 | Pass |

## House Duck 작업 종료 규칙

- QA 전에 이미 실행 중인 Godot·MCP·디버그 프로세스의 PID를 기록한다.
- 에이전트가 새로 띄운 백그라운드 프로세스는 PID나 실행 세션을 보관하고 성공·실패와 관계없이 종료한다.
- Godot 게임은 `scene stop`, 에디터는 에이전트가 직접 띄운 경우에만 정상 종료하고 자식 종료를 기다린다.
- 완료 직전에 새 Godot·`godot-mcp`·`lldb`·`adb`·Gradle 프로세스와 MCP 포트가 남지 않았는지 확인한다.
- 기존 사용자 프로세스를 무차별 `pkill`하지 않는다. 잔존 항목은 0건 또는 PID와 유지 이유를 보고한다.
- 생성된 캡처·리포트는 확인 후 `qa_output/`에서 지우고 `.gitkeep`만 남긴다.

## 현재 증거

- catalog, challenge rules, run engine: PASS
- main scene, 공통 UI, 층별 도전 씬 계약, 자동 15층 상태 흐름: PASS
- 고정 시드 424242: 15층 완주, 스토리 3비트, 광고/결제 동등성, 체크포인트 복원 PASS
- 10,000런: 불가능 상태 0, 광고/결제 불일치 0
- 파일 크기와 core 의존성 검사: PASS
- 층 전환 회귀 테스트: Timing Ring·Tap Panic·Drag Dodge 교대, 짧은 예고, 자동 결과 전환 PASS
- 2.5D 무대 회귀 테스트: 고정 직교 사선 카메라, 픽셀 `Sprite3D`, 실제 콜라이더 충돌, 회피·근접 회피·벽 소멸 PASS
- Godot MCP macOS 런타임: 타이밍 탭, 색·도형 선택, 직접 마우스 드래그, CLEAR·BONK 피드백, 다음 층 진입 PASS
- 결과 버튼 회귀 테스트: 신호 처리 중 locked object 크래시 재현 후 수정 PASS
- 앱 셸 회귀 테스트: 시작 배너, 홈, 설정, 10개 언어와 취소, 독일어 실시간 전환, 홈 복귀, 플레이 진입 PASS
- 선택 팝업 회귀 테스트: 세로 VBox, 세로 스크롤, 긴 독일어 줄바꿈, 96px 터치 높이 PASS
- 선택 팝업 반복 입력 회귀 테스트: 연타해도 콜백과 상태 전이 1회 PASS
- 실제 `ui_cancel` 입력: 언어 팝업만 닫기 → 설정 유지 → 두 번째 입력으로 홈 복귀 PASS
- 런 재시작·종료 정리 회귀 테스트: 활성 도전 1개, 중복 마스코트·퇴역 도전 잔존 0건 PASS
- Godot GUI 내장 691×1537(9:20) 런타임: 한국어 홈, 독일어 장문 설정, 아랍어 RTL 설정의 잘림·겹침 0 PASS
- Godot MCP 720×1280 직접 런타임: 세 미니게임, 2.5D 장애물 접근·회피·충돌, 결과 전환 PASS
- 현재 검증 구간 런타임 오류: 0

## 아직 증명하지 않은 것

사용자 입력만으로 15층 전체를 완주하거나 게임오버·재시작하는 흐름은 아직 검증하지 않았다. 설정 토글은 실제 오디오·햅틱에 연결되지 않고 저장되지 않는다. macOS 마우스와 자동 흐름 검증은 재미, 실제 손가락 회피 손맛, Android/iOS 안전 영역과 3D 성능, 햅틱, 오디오, 네이티브 광고, 스토어 결제, Supabase, 실제 친구·랭킹 네트워크를 증명하지 않는다. headless 외부 게임창은 맥 화면 높이 제한으로 9:20을 유지하지 않으므로 Visual 증거에는 GUI 내장 재생만 사용한다.

출시 export 전에는 `godot_mcp` 플러그인을 비활성화해 개발용 MCP autoload 2개가 제거됐는지 확인한다.
