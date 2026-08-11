# Gate A QA Report

Date: **2026-08-11**
Branch: **`codex/reboot-vertical-slice`**
Runtime source: **`c66e2e0b6221a7c82a33b9385966aab766ea6fe7`**
Visual evidence: **`6b9818ba1796e5aef76fe3c3a101a0cb170ae300`**
Capture cleanup: **`e85ecac57956420ccb473b0e504031c93e349ac3`**

## Verdict

Gate A 구현 후보와 macOS Desktop QA 증거는 생성됐다. 그러나 GA-01·03·04·08·09·11은 `Partial`, 외부 5인 재미 검증 GA-12는 `Blocked`다. **Gate A는 통과하지 않았다.**

## Automated and runtime evidence

Godot 4.7에서 다음 스크립트가 각각 `PASS`했다.

- `scripts_dev/qa/headless/flock_run_state_test.gd`
- `scripts_dev/qa/headless/flock_world_test.gd`
- `scripts_dev/qa/headless/app_shell_test.gd`
- `scripts_dev/qa/headless/ui_foundation_test.gd`
- `scripts_dev/qa/headless/main_scene_test.gd`
- `scripts_dev/qa/headless/mascot_guide_test.gd`
- `bash scripts_dev/qa/check_project.sh`

이 결과는 상태·노드·입력·실제 collider·신호·재시작 계약을 증명한다. 실제 스마트폰 손맛, 성능, 오디오, 햅틱, 사람 재미는 증명하지 않는다.

### House Duck executed TC records

`Partial` 요구사항은 실행 범위의 `Pass`와 남은 `Blocked/Not Tested`를 한 행에서 분리했다. 행동·기대결과의 전체 계약은 [`FEATURE_TEST_MAP.md`](../../docs/reboot/FEATURE_TEST_MAP.md)에 있다.

| TC ID | 분류 / 우선순위 | 사전조건 | 행동 | 기대결과 | 플랫폼 / 방법 | 결과 | 증거 / 이슈 |
|---|---|---|---|---|---|---|---|
| `QT-RB-TC-BAT-001` | BAT / P0 | 메인 씬·1080×2400 설정, fresh app instance | 메인 씬 파싱·기동 후 boot/entry 캡처 | 앱 셸 오류 0, centered 720×1280 safe frame | Common 자동 + Desktop QA 혼합 | `Pass` (macOS/headless) | `main_scene_test.gd`, `check_project.sh`, `after/boot.png`, `after/entry.png`; Android/iOS `Not Tested` |
| `QT-RB-TC-CORE-001` | BAT+Feature / P0 | seed `424242`, 새 `FlockRunState` | Entry→Brawl→Chain→3택을 한 번 진행 | 같은 리더·동료·상태·원장이 막 사이 유지 | Common 자동 + Desktop QA 화면 | `Pass` | `flock_run_state_test.gd`, `flock_world_test.gd`, entry/choice/result PNG; 이슈 없음 |
| `QT-RB-TC-TRANSITION-001` | Risk / P0 | active pointer, act/overlay/focus/home 경계 | 두 번째 pointer·focus out·choice·home·restart 교차 | pointer 1개, 경계에서 취소, trial 1개 | Common 자동 | 실행 경로 `Pass`; drag→popup stale release `Not Tested` | `flock_world_test.gd`, `app_shell_test.gd`; 요구사항 verdict `Partial` |
| `QT-RB-TC-ENTRY-001` | Feature+Visual / P0 | Entry, 세 route marker, 실제 Rescue collider | drag로 리더 이동 후 Rescue overlap | 리더 이동, 거위·비둘기 1회 구조, render beat 유지 | Common 자동 + Desktop QA 화면 | runtime/visual `Pass`; Human `Blocked` | `flock_world_test.gd`, `after/entry.png`; hazard/dodge 실행 `Not Tested` |
| `QT-RB-TC-BRAWL-001` | Feature+Visual / P0 | Brawl weak point, swipe 후보 | 짧은 실패 swipe와 유효 dash-contact 실행 | 실패 swipe 무효, warning→contact→rebound 분리 | Common 자동 + Desktop QA 화면 | runtime/visual `Pass`; Human `Blocked` | `flock_world_test.gd`, brawl 3 PNG; 원인 이해는 외부 5인 필요 |
| `QT-RB-TC-CHAIN-001` | Feature+Visual / P0 | Chain, 0/1/3 target, 실제 collider | broken release·cancel·retry·3-target release | 경로 순서·1회 strike·1회 reward, broken 이유 표시 | Common 자동 + Desktop QA 화면 | `Pass` | `flock_world_test.gd`, chain 3 PNG; 이슈 없음 |
| `QT-RB-TC-COLLAPSE-001` | Feature+Visual / P0 | Brawl 실제 weak point와 pre-cut pieces | contact·cancel·retry·restart 실행 | crack→pieces→target→reward, 중복 보상 0 | Common 자동 + Desktop QA 화면 | runtime/visual `Pass`; Human `Blocked` | `flock_world_test.gd`, collapse 4 PNG; 원인 이해는 외부 5인 필요 |
| `QT-RB-TC-RNG-001` | Feature / P0 | 같은 seed의 독립 상태 2개 | 선택지·build·event ledger·snapshot 비교 | 같은 seed의 이산 결과 동일 | Common 자동 | same-seed `Pass`; different-seed `Not Tested` | `flock_run_state_test.gd`; 다른 seed 분기 증거 없음 |
| `QT-RB-TC-REWARD-001` | Feature+Visual / P0 | KO, seed `424242`, 구역 종료 | 세로 3택 연타 후 첫 선택 1회 | 카드 3개, callback·mutation 1회, 결과에 선택명 | Common 자동 + Desktop QA 화면 | Gate A KO `Pass`; 후속 act·DE/AR `Not Tested` | `ui_foundation_test.gd`, `app_shell_test.gd`, choice/result PNG |
| `QT-RB-TC-RESET-001` | Risk / P0 | 완료·home·restart 경계 | 같은 앱에서 반복 재시작 | 이전 trial 해제, 새 trial·guide 정확히 1개 | Common 자동 | home/restart `Pass`; failure `Not Tested` | `flock_world_test.gd`, `app_shell_test.gd`; 요구사항 verdict `Partial` |
| `QT-RB-TC-UI-001` | Visual / P1 | KO choice/result, 720×1280 safe frame | popup·choice·result를 20:9로 캡처 | 세로 카드·CTA·마스코트가 잘리지 않고 중복 0 | Desktop QA 혼합 | KO 화면 `Pass`; token 전후·긴 언어 `Not Tested` | choice/result PNG; 요구사항 verdict `Partial` |
| `QT-RB-TC-MASCOT-001` | Visual+Human / P1 | Entry·impact·choice·result | 각 상태에서 guide visibility/중복 검사 | 화면당 guide 1개, 행동·CTA 비가림 | Common 자동 + Desktop QA 화면 | visual `Pass`; Human `Blocked` | `mascot_guide_test.gd`, entry/contact/choice/result PNG |
| `QT-RB-TC-VISUAL-001` | Visual / P0 | runtime `c66e2e0`, `ko`, seed `424242` | 실제 앱 입력으로 14상태 캡처·원본 리뷰 | 14장 1080×2400, 고유 hash, P0/P1 0 | macOS Desktop QA 혼합 | after `Pass`; 동등 before `Not Tested` | `after/README.md`; legacy before는 `not directly comparable` |
| `QT-RB-TC-PROCESS-001` | Risk / P0 | baseline에 무관한 Quirky Ball PID `4266` 존재 | 테스트·캡처·cleanup self-test 후 PID/포트 비교 | 새 agent-owned PID/listener 0, PID `4266` 보존 | macOS 자동 | `Pass` | `run_gate_a_visual.sh --self-test-cleanup`; 이슈 없음 |
| `QT-RB-TC-DOC-001` | Data / P1 | Task 9 정본 4개·계획·QA report | 링크·ID·size·diff·legacy 경계 검사 | 깨진 내부 링크·중복 ID·diff 오류 0, WORK_STATE 한도 준수 | Common 자동 | `Pass` | 최종 정적 검사 기록; 이슈 없음 |

## Visual evidence

Final capture metadata and SHA-256 values: [`after/README.md`](after/README.md)

- Platform: macOS desktop QA, Metal Forward Mobile, Apple M2
- Godot: 4.7 stable
- Locale/seed: `ko` / `424242`
- Physical/logical viewport: `1080×2400` / `720×1600`
- Authored safe frame: centered `720×1280`
- Source: `res://scenes/app/main.tscn`, one app instance
- Input: `SubViewport.push_input()` touch, drag, and release
- States: boot, entry, Brawl warning/contact/rebound, Chain path/broken/strike, collapse crack/pieces/target/reward, choice, result

14개 PNG는 모두 1080×2400이고 해시가 서로 다르며 README 값과 일치한다. 독립 원본 크기 리뷰에서 Critical/Important 및 화면 P1은 0이었다.

Legacy before: [`before/README.md`](before/README.md). Timing Ring 화면이므로 리부트 상태와 `not directly comparable`이며 GA-01과 `QT-RB-TC-VISUAL-001`은 `Partial`이다.

## Requirement reconciliation

상세 구현 파일·테스트·스크린샷 연결은 [`Gate A plan`](../../docs/superpowers/plans/2026-08-11-gate-a-90s-greybox.md#requirement--implementation--evidence-checklist)에 있다.

| Requirement | Verdict | Evidence boundary |
|---|---|---|
| GA-01 | `Partial` | 20:9·safe frame은 확인했지만 동등 비포 없음 |
| GA-02 | `Complete` for Gate A implementation scope | Headless/runtime/visual; Human 별도 |
| GA-03–04 | `Partial` | popup stale-release와 hazard/dodge 실행 미검증; Human 이해도 별도 |
| GA-05–07 | `Complete` for Gate A implementation scope | Headless/runtime/visual; Human 이해도는 GA-12 |
| GA-08 | `Partial` | 같은 seed 이산 결과만 확인, 다른 seed 분기 미검증 |
| GA-09 | `Partial` | 세로 3택·한 번 mutation은 확인, 후속 두 막·DE/AR 미검증 |
| GA-10 | `Complete` for KO Desktop QA | 전 언어·Human·Device 별도 |
| GA-11 | `Partial` | home/restart cleanup은 확인, failure 재시작 미검증 |
| GA-12 | `Blocked` | 외부 5인 관찰·원본 기록 없음 |
| GA-13 | `Complete` for this branch handoff | 최종 회귀·구조·cleanup self-test와 PID/포트 확인; commit/push는 Git handoff에서 확인 |

## Process evidence

- Final visual capture PID `37731` completed in 9.09s.
- Capture 종료 뒤 Task-owned Godot/MCP PID와 관련 listener는 0이었다.
- 기존 Quirky Ball PID `4266`은 시작 전부터 존재한 다른 작업이므로 신호를 보내지 않았다.
- `run_gate_a_visual.sh --self-test-cleanup`은 소유 부모·자식만 TERM→bounded KILL→reap하고 무관한 sentinel을 보존해 `PASS`했다.
- Runner cleanup 독립 리뷰: Critical 0, Important 0.

## Still unverified

- 외부 5인의 첫 행동, 충돌·붕괴 인과, 3막 구분, 자발 재도전
- popup stale-release, hazard/dodge, different-seed, failure restart focused 경로
- Android/iPhone 실기기 입력·safe area·성능·오디오·햅틱
- Gate B 5분 런과 선택 효과의 후속 두 막 반영
- `quirky_tower_urban_broadcast_cel_v1` 최종 2D·3D·profile·shop·frame 아트
- AdMob, Billing, StoreKit, Supabase, 실제 랭킹·국가/소속
