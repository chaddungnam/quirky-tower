# Quirky Tower Reboot Feature → Test Map

상태: **Approved for Gate A implementation / 아직 실행되지 않음**
기준일: **2026-08-11**
결정 정본: [`DECISION_REGISTER.md`](DECISION_REGISTER.md)

이 표는 “코드가 있다”와 “게임이 된다”를 구분한다. 모든 행의 현재 결과는 `Not Tested`이다. 기존 15층 프로토타입 PASS를 새 코어의 PASS로 이월하지 않는다.

## 증거 종류

| 증거 | 증명하는 것 | 증명하지 않는 것 |
|---|---|---|
| `STATIC` | 경로, 참조, 파일 크기, 금지 의존성, import 계약 | 실행, 물리, 재미 |
| `HEADLESS` | 동일 Godot 4.7 CLI에서 시드 규칙, 상태 연속성, 보상 중복, 저장·경제 이산 로직 | 실제 물리 재현성, 손맛, 화면, 오디오; 엔진 없는 Cloud에서는 실행 불가 |
| `RUNTIME` | Godot 노드, collider, signal, 입력, 애니메이션 연결 | 실기기 성능과 사람 재미 |
| `VISUAL` | 20:9 화면, 가독성, 전환, 다국어 overflow | 터치 감각, 네이티브 SDK |
| `DEVICE` | Android/iOS 성능, safe area, 손가락 입력, 햅틱, 오디오, resume | 장기 유지율과 BM 성과 |
| `HUMAN` | 이해도, 재미, 원인 인식, 카타르시스, 재도전 의향 | 서버 무결성과 대규모 통계 |
| `ANALYTICS` | 이벤트 schema, payload 예산, cohort·시간창 계산 | 실제 retention·매출 개선 |
| `NETWORK` | 요청 인증, retry, timeout, 중복 제출 처리 | 클라이언트 화면과 스토어 소유권 |
| `SECURITY` | 권한·서버 검증·변조 거부 | 재미와 정상 사용자의 UX |
| `STORE` | 실제 AdMob·Billing·StoreKit·스토어 복구 | 게임 재미와 유지율 |

## House Duck 공통 TC 적용

이 파일은 요구사항→테스트의 **계획 지도**이며 실행 결과표를 대신하지 않는다. 실행 전 각 TC ID는 정본 [`../../../shared/standards/house_duck_test_case_standard.md`](../../../shared/standards/house_duck_test_case_standard.md)의 `분류·우선순위·사전조건·행동·기대결과·플랫폼·자동화 명령/캡처·결과·증거·이슈` 필드를 가진 실행 기록으로 확장한다.

- `STATIC/HEADLESS/RUNTIME/...`은 증거 종류이며 BAT/BVT/Feature/Risk/Visual/Device/Data 스위트와 섞지 않는다.
- Gate A 코어·기동·입력·전환·중복 보상은 `P0`, Gate B~C의 아트·오디오·화면은 구현 중 `P1`, 실제 SDK·export는 Gate D부터 `P0`다.
- 플랫폼은 `HEADLESS=Common`, `RUNTIME=Desktop QA`, `DEVICE/STORE=Android·iOS 별도`로 시작하되 계획에서 목표 기기·build·명령을 구체화한다.
- 자동화 명령과 증거 경로가 아직 없으므로 모든 현재 결과는 `Not Tested`다. 빈 P0 결과나 증거 없는 Pass는 gate를 통과시키지 않는다.

## P0 코어 지도

| TC ID | 관련 결정 | 증거 | 검증 행동 | 통과 기준 | 단계 | 현재 |
|---|---|---|---|---|---|---|
| `QT-RB-TC-BAT-001` | `QT-RB-UI-001`, `QT-RB-TECH-001` | `STATIC+RUNTIME` | 프로젝트를 파싱하고 메인 씬을 실행한다. | 오류 없이 앱 셸이 뜨고 기본 창은 1080×2400이다. 논리 기준 720×1280 safe frame은 명시적으로 가운데 정렬되고 20:9 추가 영역은 배경·월드에만 확장된다. | Greybox | `Not Tested` |
| `QT-RB-TC-CORE-001` | `QT-RB-PROD-001`, `QT-RB-GAME-001`, `QT-RB-GAME-002`, `QT-RB-GAME-003`, `QT-RB-TECH-003` | `HEADLESS` | 한 시드로 진입→난투→사슬→3택을 한 번 진행한다. | 같은 `RunState`의 리더, 동료≤5, 체력, 빌드, 콤보가 막 사이에 보존된다. | Greybox | `Not Tested` |
| `QT-RB-TC-TRANSITION-001` | `QT-RB-GAME-003`, `QT-RB-GAME-012` | `RUNTIME+VISUAL` | drag 중 막 전환, popup, focus loss, 정상 전환을 교차한다. | 로딩 화면·HUD 초기화·유령 release·유령 dash가 없고 새 막의 첫 touch부터 현재 router 하나가 소유한다. | Greybox | `Not Tested` |
| `QT-RB-TC-RNG-001` | `QT-RB-GAME-006`, `QT-RB-GAME-010`, `QT-RB-TECH-002`, `QT-RB-TECH-007` | `HEADLESS` | 같은 시드 두 런과 다른 시드 한 런의 이산 규칙 원장을 비교한다. | 같은 시드는 영입·조우·3택·지원 효과·event ledger가 같고 다른 시드는 허용 범위에서 달라진다. cosmetic RNG와 물리 위치는 checksum에 들어가지 않는다. | Greybox | `Not Tested` |
| `QT-RB-TC-RETRY-001` | `QT-RB-GAME-013`, `QT-RB-BM-002`, `QT-RB-BM-011` | `HEADLESS+RUNTIME` | 막 실패 뒤 광고·결제 source ticket으로 각각 재도전한다. | 막 시작 snapshot과 gameplay RNG가 같게 복원되고 callback은 RNG를 진행하지 않는다. `retry_count`와 모든 시도의 active time은 누적되며 보상은 한 번이다. | Mock BM | `Not Tested` |
| `QT-RB-TC-MERGE-001` | `QT-RB-GAME-010` | `HEADLESS` | 같은 동료 중복 획득과 연타 입력을 재현한다. | 합성 후보와 보상은 정확히 한 번 생기고 동료 수가 5를 넘지 않는다. | Greybox | `Not Tested` |
| `QT-RB-TC-ENTRY-001` | `QT-RB-PROD-002`, `QT-RB-GAME-004`, `QT-RB-GAME-007`, `QT-RB-GAME-012` | `RUNTIME+HUMAN` | 드래그로 세 경로를 오가고 구조·장애물·근접 회피를 시도한다. | 리더가 손을 따라가고 동료가 읽히게 추종한다. 구조와 충돌의 원인을 설명 없이 말할 수 있다. | Greybox | `Not Tested` |
| `QT-RB-TC-BRAWL-001` | `QT-RB-GAME-004`, `QT-RB-GAME-007`, `QT-RB-GAME-008`, `QT-RB-GAME-012` | `RUNTIME+HUMAN` | 이동·짧은 스와이프로 적을 벽과 구조물에 날린다. | 대시 방향이 결과를 바꾸며 예고→충돌→피해→반동이 분리되어 보인다. drag release가 임의 대시로 오인되지 않는다. | Greybox | `Not Tested` |
| `QT-RB-TC-CHAIN-001` | `QT-RB-GAME-007`, `QT-RB-GAME-008`, `QT-RB-GAME-009` | `HEADLESS+RUNTIME` | 동료·약점을 경로로 잇고 손을 떼며 같은 목표를 두 번 경유한다. | 연결 순서대로 한 번씩 돌진하고 같은 목표의 파괴·보상이 중복 지급되지 않는다. 끊긴 지점이 보인다. | Greybox | `Not Tested` |
| `QT-RB-TC-COLLAPSE-001` | `QT-RB-GAME-008`, `QT-RB-TECH-004`, `QT-RB-TECH-007` | `RUNTIME+VISUAL+HUMAN` | 약점 충돌로 authored destruction을 발동한다. | 실제 collider 결과가 균열→부품→층→적→보상 순으로 이어지고 원인 없는 자동 붕괴가 없다. 정확 trajectory 재현은 PASS 조건이 아니다. | Greybox | `Not Tested` |
| `QT-RB-TC-REWARD-001` | `QT-RB-GAME-006`, `QT-RB-UI-003`, `QT-RB-UI-009`, `QT-RB-UI-011` | `HEADLESS+VISUAL` | 구역 종료 3택을 여러 언어와 반복 입력으로 선택한다. | 세로 카드 3개, 96px 후보 높이, 최대 2줄 기본 설명, 단일 콜백, 다음 구역 상태 반영을 만족한다. | Greybox | `Not Tested` |
| `QT-RB-TC-RESET-001` | `QT-RB-GAME-003`, `QT-RB-QA-005` | `HEADLESS+RUNTIME` | 실패, 홈 이동, 재시작을 반복한다. | 활성 phase·마스코트·임시 collider·signal 연결이 한 벌만 남고 이전 런 상태가 섞이지 않는다. | Greybox | `Not Tested` |
| `QT-RB-TC-PACING-001` | `QT-RB-GAME-005`, `QT-RB-GAME-011`, `QT-RB-QA-002`, `QT-RB-QA-003`, `QT-RB-QA-004` | `RUNTIME+HUMAN+ANALYTICS` | Gate A 5명과 Gate B 10명 이상의 act·wall·active time, 첫 행동, 재도전을 기록한다. | Gate A 4/5 이해·인과·3막 구분, 3/5 자발 재도전과 Gate B 후보 wall time·빌드 설명·카타르시스 기준을 충족한다. | Greybox/5-minute | `Not Tested` |

## UI, 이야기, 아트

| TC ID | 관련 결정 | 증거 | 검증 행동 | 통과 기준 | 단계 | 현재 |
|---|---|---|---|---|---|---|
| `QT-RB-TC-UI-001` | `QT-RB-UI-002`, `QT-RB-UI-003`, `QT-RB-UI-004`, `QT-RB-UI-005`, `QT-RB-UI-010` | `STATIC+VISUAL` | 공통 token 하나를 바꾸고 홈·HUD·3택·결과를 캡처한다. | 색·간격·반경·글자가 직접 상수 없이 함께 바뀌며 등장 순서가 배경→주체→맥락→행동이다. | Art/UI | `Not Tested` |
| `QT-RB-TC-SCREEN-001` | `QT-RB-UI-007`, `QT-RB-UI-011`, `QT-RB-UI-012`, `QT-RB-BM-007` | `STATIC+RUNTIME+VISUAL` | 필수 화면별 진입·주 CTA·back·empty/loading/error와 popup 중 back을 순회한다. | 화면 계약 누락 0, modal owner 한 개, 최상단 popup만 닫힘, freeze·입력 잠금·데이터 출처가 일치한다. | Outgame | `Not Tested` |
| `QT-RB-TC-I18N-001` | `QT-RB-UI-003`, `QT-RB-UI-006`, `QT-RB-UI-009`, `QT-RB-UI-013` | `VISUAL` | KO·EN·DE·JA·AR에서 홈, 설정, 3택, 결과, 상점을 20:9와 작은 safe area로 본다. | 잘림·겹침·가로 스크롤·CTA ellipsis가 없고 RTL 방향이 맞으며 숫자·방향 고정 아이콘은 잘못 미러링되지 않는다. | Art/UI | `Not Tested` |
| `QT-RB-TC-MASCOT-001` | `QT-RB-MASCOT-001`, `QT-RB-MASCOT-002` | `VISUAL+HUMAN` | 시작, 위험 전, 성공, 실패, story beat에서 말풍선을 재생한다. | 한 문장·두 줄 이내, 플레이 영역 비가림, 시스템 문구 비중복, 행동 방해 0건이다. | Art/UI | `Not Tested` |
| `QT-RB-TC-STORY-001` | `QT-RB-STORY-001`, `QT-RB-STORY-002`, `QT-RB-STORY-003`, `QT-RB-STORY-004` | `HUMAN` | 스토리 승인 뒤 설명서 없이 한 런 후 목표·비밀·다음 런 이유를 묻는다. | 5명 중 4명 이상이 동료 구조·조작된 방송·송출실 탈취 중 둘 이상과 새 생방송 회차라는 재도전 이유를 말한다. | 5-minute | `Not Tested` |
| `QT-RB-TC-CAST-001` | `QT-RB-CAST-001`, `QT-RB-CAST-002`, `QT-RB-CAST-003`, `QT-RB-CAST-004`, `QT-RB-CAST-005` | `STATIC+VISUAL` | 기본 종의 첫 동료 data와 구조·충돌·성공·실패 판을 본다. | 이름·성격·대표색·소품·필수 반응 누락 0이며 이름을 가려도 종과 역할을 구분한다. 치킨은 승인 전 후보 표시다. | Art/UI | `Not Tested` |
| `QT-RB-TC-ART-001` | `QT-RB-ART-001`, `QT-RB-ART-002`, `QT-RB-ART-003`, `QT-RB-ART-004`, `QT-RB-ART-005`, `QT-RB-ART-006`, `QT-RB-ART-007`, `QT-RB-ART-008`, `QT-RB-ART-010`, `QT-RB-ART-011`, `QT-RB-ART-012`, `QT-RB-ART-013` | `STATIC+VISUAL` | 오리 마스터의 2D·crop·상점·3D·공통 애니메이션·실루엣 비교판을 만든다. | 같은 ID·체형·복장선·대표색·좌상단 광원과 crop safe area가 유지되고 Project K 팔레트·박스 3D를 복제하지 않는다. | Art/UI | `Not Tested` |
| `QT-RB-TC-ASSET-001` | `QT-RB-ART-003`, `QT-RB-ART-007`, `QT-RB-ART-012`, `QT-RB-ART-013` | `STATIC` | `asset_manifest`의 경로, 해시, 라이선스, 공용 frame·animation 참조를 검사한다. | 누락·중복 ID 0, 캐릭터별 frame 복제 0, 이미지 내 번역 텍스트 0, 필수 animation 누락 0이다. | Art/UI | `Not Tested` |

## 오디오, 햅틱, 성능

| TC ID | 관련 결정 | 증거 | 검증 행동 | 통과 기준 | 단계 | 현재 |
|---|---|---|---|---|---|---|
| `QT-RB-TC-AUDIO-001` | `QT-RB-AUDIO-001`, `QT-RB-AUDIO-002`, `QT-RB-AUDIO-003`, `QT-RB-AUDIO-004` | `STATIC+RUNTIME` | 4스템을 동기 재생하고 세 막과 보상 상태를 왕복한다. | 위상·마디가 어긋나지 않고 클릭·무음 틈 없이 다음 마디에서 전환한다. SFX가 행동 즉시 들린다. | Art/Audio | `Not Tested` |
| `QT-RB-TC-LISTEN-001` | `QT-RB-AUDIO-001`, `QT-RB-AUDIO-005` | `DEVICE+HUMAN` | Android/iOS 스피커·이어폰에서 베이스만, 상부만, 전체를 듣는다. | 베이스·킥만으로 20초 이상 그루브가 서고 독립 고음·화성 충돌·7~8초 무변화 반복이 없다. loudness는 전체 루프 구간에서 측정한다. | Device | `Not Tested` |
| `QT-RB-TC-HAPTIC-001` | `QT-RB-HAPTIC-001`, `QT-RB-UI-008` | `DEVICE` | 근접 회피·대시·붕괴·보상을 연속 실행하고 진동 off를 전환한다. | 사건이 구분되며 120ms 후보 중복 진동이 합쳐지고 off에서는 진동 0이다. | Device | `Not Tested` |
| `QT-RB-TC-PERF-001` | `QT-RB-TECH-001`, `QT-RB-TECH-004`, `QT-RB-TECH-006`, `QT-RB-OPS-002` | `DEVICE` | 목표 저사양 Android에서 최악의 난투·붕괴를 10회 반복한다. | 목표 60fps에서 p95 frame time≤16.7ms 후보, 입력 지연 체감 없음, 메모리 상승이 반복 후 안정된다. | Device | `Not Tested` |

## BM, 랭킹, 저장, SDK

| TC ID | 관련 결정 | 증거 | 검증 행동 | 통과 기준 | 단계 | 현재 |
|---|---|---|---|---|---|---|
| `QT-RB-TC-BM-001` | `QT-RB-BM-001`, `QT-RB-BM-002`, `QT-RB-BM-003` | `HEADLESS` | 광고 획득·결제 획득 티켓 한 단위로 각 사용처를 실행한다. | inventory ID, 효과, 확률, RNG·event ledger가 같고 source는 분석 원장 외 판정에 쓰이지 않는다. 일일 획득량은 이 동등성 검사의 범위가 아니다. | Mock BM | `Not Tested` |
| `QT-RB-TC-ECONOMY-001` | `QT-RB-BM-007`, `QT-RB-BM-008`, `QT-RB-BM-009`, `QT-RB-BM-010`, `QT-RB-ANALYTICS-001` | `HEADLESS+ANALYTICS` | Gate C 뒤 후보 광고 상한·가격·부스트를 다수 seed와 세션 길이에 대입한다. | 유료 전용 효과·slot이 없고 candidate cap·interval을 일관 적용하며 수치는 사람 재미·실제 광고 지표 전 LOCKED가 아니다. | Mock BM | `Not Tested` |
| `QT-RB-TC-RANK-001` | `QT-RB-BM-004`, `QT-RB-BM-005`, `QT-RB-BM-011`, `QT-RB-TECH-007` | `HEADLESS` | 무지원·광고·결제 런을 점수·친구·타임어택·소속 보기로 조회한다. | 모두 같은 record pool에 있고 점수는 score↓, 타임어택 완주 기록은 모든 시도의 active time↑→score↓→run_id로 안정 정렬된다. 물리 재시뮬레이션은 검증 근거가 아니다. | Backend | `Not Tested` |
| `QT-RB-TC-AFFIL-001` | `QT-RB-BM-006`, `QT-RB-BM-012` | `HEADLESS+VISUAL` | 실제 국가와 유머 소속을 선택하고 기록 제출 뒤 소속을 바꾼다. | 하나의 `affiliation_code` 목록과 `국가/소속` UI를 쓰며 자동 위치 추정이 없다. 과거 기록은 제출 당시 snapshot을 유지한다. | Backend | `Not Tested` |
| `QT-RB-TC-SAVE-001` | `QT-RB-TECH-002`, `QT-RB-TECH-005`, `QT-RB-DOC-004` | `HEADLESS` | 런 저장, 앱 중단, 순차 migration, 손상 payload를 재현한다. | 유효 상태는 복원되고 손상 데이터는 crash·중복 보상 없이 해당 복원만 포기한다. one-shot reward ledger와 랭킹 기록은 중복되지 않는다. | 5-minute | `Not Tested` |
| `QT-RB-TC-ANALYTICS-001` | `QT-RB-ANALYTICS-001`, `QT-RB-ANALYTICS-002`, `QT-RB-ANALYTICS-003` | `STATIC+ANALYTICS` | event schema와 synthetic install/session 시간을 검증한다. | 광고·구매 결과 상태 누락 0, 5분 런 payload 예산 준수, D1 24~48h·D7 144~192h 경계값이 정확하고 미성숙 cohort는 제외된다. | Analytics | `Not Tested` |
| `QT-RB-TC-AD-001` | `QT-RB-BM-009`, `QT-RB-PLUGIN-004`, `QT-RB-ANALYTICS-001` | `DEVICE+STORE` | 보상형 완료·취소·실패·no-fill, 전면 광고 dismiss, focus loss 순서를 교차한다. | 완료만 보상 1개, 취소·실패·no-fill은 0개다. 입력·오디오는 한 번만 복구되고 중복 fullscreen·게임 중 배너가 없다. | SDK | `Not Tested` |
| `QT-RB-TC-PURCHASE-001` | `QT-RB-BM-001`, `QT-RB-PLUGIN-004`, `QT-RB-ANALYTICS-001` | `DEVICE+STORE` | 구매 성공·취소·실패·중복 callback·restore를 실제 sandbox에서 실행한다. | 동일 transaction 중복 지급 0, 취소·실패 지급 0, restore 후 동일 Sponsor Ticket·권한이 복원된다. | SDK | `Not Tested` |
| `QT-RB-TC-EXPORT-001` | `QT-RB-PLUGIN-001`, `QT-RB-PLUGIN-002`, `QT-RB-PLUGIN-003`, `QT-RB-PLUGIN-005` | `STATIC+DEVICE` | 설치 addon과 모든 release preset의 설정, PCK, autoload 목록을 검사한다. | 개발 플러그인은 승인된 MCP pin 하나뿐이고 release에서는 plugin 비활성, autoload 2개 없음, addon exclude 적용, PCK 문자열 0이다. | Release | `Not Tested` |

## 문서·운영 회귀

| TC ID | 관련 결정 | 증거 | 검증 행동 | 통과 기준 | 단계 | 현재 |
|---|---|---|---|---|---|---|
| `QT-RB-TC-DOC-001` | `QT-RB-DOC-001`, `QT-RB-DOC-002`, `QT-RB-DOC-003`, `QT-RB-DOC-004`, `QT-RB-DOC-005`, `QT-RB-DOC-006` | `STATIC` | 문서 ID·링크·크기·legacy 경계와 WORK_STATE를 검사한다. | 중복·누락 ID/링크 0, 기준 파일이 후보 한도 안이며 구 15층 canonical을 새 정본으로 읽지 않는다. | Every task | `Not Tested` |
| `QT-RB-TC-VISUAL-001` | `QT-RB-QA-007` | `VISUAL` | 화면 결과가 바뀌는 구현의 비포·애프터를 최종 코드에서 캡처하고 명세→구현→증거를 대조한다. | 같은 상태·범위의 최종 코드 1080×2400 PNG 비포·애프터가 있으며, 실제 기기와 외부 사람 검증은 별도 증거로 기록한다. | Every visual task | `Not Tested` |
| `QT-RB-TC-PROCESS-001` | `QT-RB-OPS-001`, `QT-RB-OPS-003`, `QT-RB-QA-006` | `STATIC+RUNTIME` | Local 작업 전후 PID·포트·Git 상태를 비교한다. | baseline 대비 새 agent-owned Godot·MCP·debug 잔존 0, 사용자 프로세스 종료 0, 의도하지 않은 Git 변경 0이다. | Every Local gate | `Not Tested` |

## 사람 재미 게이트

### Gate A — 90초 greybox

- 범위: 오리 리더, 거위·비둘기 동료, 한 구역, 세 막, 3택 한 번.
- 참여자: 개발자 외 최소 5명.
- 통과:
  - 5명 중 4명 이상이 10초 안에 이동·대시·경로 release 중 다음 행동을 설명 없이 시도한다.
  - 5명 중 4명 이상이 충돌과 붕괴의 원인을 맞게 말한다.
  - 5명 중 4명 이상이 진입·난투·사슬의 차이를 설명한다.
  - 5명 중 3명 이상이 요청 없이 즉시 다시 한다.
  - 심각한 멀미·입력 불능·원인 불명 붕괴가 1건이라도 있으면 수정 후 다시 검증한다.
- 실패 시: 아트·상점·SDK를 늘리지 않고 코어 입력·인과·페이싱을 고친다.

### Gate B — 5분 런

- 범위: 세 구역, 최종 송출실, 닭·까마귀 포함, 3택 세 번, 한 개 완성 빌드.
- 참여자: 개발자 외 최소 10명, 가능하면 Gate A 미참여자 포함.
- 시간: `run_start`부터 `run_end`까지 선택·전환은 포함하고 수동 pause·광고·background는 뺀 wall time을 4분 30초~5분 30초 후보로 본다. 타임어택 active time은 선택·전환도 제외한다.
- 통과:
  - 첫 런 완주 여부와 관계없이 70% 이상이 자신이 고른 빌드를 한 문장으로 말한다.
  - 60% 이상이 가장 통쾌한 충돌·붕괴 장면을 구체적으로 기억한다.
  - 60% 이상이 한 번 더 다른 빌드를 시도한다.
  - 어느 phase도 평균 플레이 시간의 45%를 넘지 않는다.
  - 완주 표본의 중앙 wall time이 후보 범위 안이고, 이탈 구간을 act 단위로 식별할 수 있다.

### Gate C — 아트·오디오·outgame

- 오리 마스터 하나로 2D·3D·프로필·상점 파생 계약을 통과한다.
- 4스템과 핵심 SFX가 실제 기기에서 House Duck 청음 게이트를 통과한다.
- 앱 시작·홈·설정·도감·프로필·상점·랭킹 mock 흐름이 20:9와 필수 언어에서 읽힌다.

### Gate D — 수익화·백엔드·출시

- Gate A~C를 먼저 통과한다.
- mock Sponsor Ticket 동등성·통합 랭킹을 headless로 통과한다.
- 이후에만 AdMob, Billing, StoreKit, Supabase를 하나씩 도입하고 각각 Store 증거를 남긴다.

## Local 작업 종료 체크

1. 시작 전 Godot·Godot MCP·adb·Gradle·lldb baseline PID를 기록한다.
2. 프로젝트 경로와 MCP 상태를 확인한다.
3. Editor는 최대 한 개만 띄운다.
4. 테스트 뒤 scene을 멈춘다.
5. 에이전트가 시작한 정확한 PID와 자식만 종료한다.
6. 포트 6505, 7777, 9080~9095, 9100~9115, 9200~9215를 확인한다.
7. 사용자 소유 프로세스에 광범위한 `pkill`을 사용하지 않는다.
8. `qa_output/`에는 `.gitkeep`과 의도한 보고서만 남긴다.
9. 최종 `git status`를 시작 상태와 비교한다.
10. 잔존 프로세스는 0건 또는 PID·유지 이유를 보고한다.
