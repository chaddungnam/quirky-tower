# Quirky Tower 최소 플레이 루프 설계

## 목표

Godot에서 프로젝트 실행 버튼을 누르면 메뉴 없이 바로 1층이 시작되고, 마우스나 터치로 15층 전체를 완주하거나 게임오버 후 재시작할 수 있다. 기존 헤드리스 core와 JSON을 그대로 사용한다.

## 플레이 흐름

```text
실행 -> 1층 -> 도전/판정 반복 -> Quirk 선택 -> 스토리 -> 15층 완료 -> 다시 시작
                              \-> 하트 0 -> 게임오버 -> 다시 시작
```

- 3종 도전은 `Timing Ring`, `Tap Panic`, `Drag Dodge`다.
- Quirk는 4·8·12층 시작 전에 아직 보유하지 않은 항목 중 하나를 선택한다.
- 스토리는 5·10·15층 성공 직후 짧은 오버레이로 표시한다.
- HUD는 층, 점수, 콤보, 하트만 표시한다.
- 완료와 게임오버 화면은 점수와 재시작 버튼만 제공한다.
- 이번 단계에는 Home, 랭킹, 광고·결제, Supabase, 저장, 오디오, 햅틱을 넣지 않는다.

## 도전 입력

- `Timing Ring`: 왕복하는 바늘을 화면 탭으로 멈추고 정중앙과의 거리를 core에 전달한다.
- `Tap Panic`: 제한시간 동안 목표 도형만 눌러 달성률 `0.0..1.0`을 전달한다.
- `Drag Dodge`: 주황색 플레이어를 드래그해 장애물을 피한다. 생존은 core의 안전 중앙값, 충돌은 실패값으로 전달한다.
- 각 도전 씬은 `finished(input_value: float)` 신호 하나만 노출한다. 한 구현뿐인 공통 베이스 클래스는 만들지 않는다.

## 화면과 폴더

기존 `scripts/core`, `data`, `scripts_dev/qa`는 이미 역할이 분명하므로 이동하지 않는다. 새 화면 계층만 다음처럼 추가한다.

```text
scenes/
  app/main.tscn
  game/run_screen.tscn
  game/challenges/{timing_ring,tap_panic,drag_dodge}.tscn
  ui/components/{run_hud,game_overlay}.tscn
scripts/
  app/main.gd
  game/run_controller.gd
  game/challenges/*.gd
  ui/*.gd
ui/themes/app_theme.tres
```

- `main.tscn`은 `run_screen.tscn`만 소유하는 고정 진입점이다.
- `RunController`만 core 상태를 변경하고, 도전 씬은 입력값만 반환한다.
- `GameOverlay` 하나를 규칙 안내, 판정, Quirk, 스토리, 종료에 재사용한다.
- 720×1280 세로 기준과 `canvas_items/expand`를 사용한다.
- 색, 글자 크기, 여백은 `AppTheme.tres`와 한 개의 UI 토큰 스크립트에서만 정의한다.

## 상태와 오류 처리

시작 시 `GameCatalog.load_default().validate()`를 실행한다. 오류가 있으면 게임을 시작하지 않고 오버레이에 첫 오류를 표시한다. 도전 결과를 받은 즉시 입력을 잠가 중복 판정을 막고, 이전 도전 씬을 제거한 뒤 다음 씬을 인스턴스화한다.

## 검증

- 먼저 메인 씬 미설정과 15층 흐름을 검사하는 실패 테스트를 추가한다.
- 구조 테스트는 main scene, 3개 도전 씬, HUD, 오버레이 경로를 확인한다.
- 기존 headless QA 전체를 다시 실행해 core 결과가 변하지 않았음을 확인한다.
- Godot MCP로 main scene을 실행하고 세 도전의 실제 입력, Quirk 선택, 스토리, 게임오버·재시작, 15층 완료를 관찰한다.
- macOS 결과와 실제 Android/iOS 터치·안전영역 검증은 구분해 보고한다.

## 완료 기준

실행 버튼 한 번으로 오류 없이 1층에 진입하고, 사용자 입력만으로 실패·재도전·Quirk·스토리를 거쳐 15층 완료 또는 게임오버 후 새 런을 시작할 수 있다.
