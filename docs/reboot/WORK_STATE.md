# Quirky Tower Reboot Work State

갱신일: **2026-08-11**
현재 단계: **Gate A implementation**
현재 브랜치: `codex/reboot-vertical-slice`
기준 코드: `0717db2` (`origin/main`과 동일했던 작성 시작 시점)

## 지금 무엇인가

Quirky Tower의 기존 15층·세 미니게임 코어를 폐기하고, 리더 1마리와 동료 최대 5마리가 같은 구역에서 `진입 → 난투 → 사슬 습격 → 랜덤 3택`을 이어가는 20:9 세로 로그라이트 액션으로 재설계한 상태다.

Gate A 승인 정본에 따라 90초 greybox를 구현한다. Godot 씬, GDScript, 에셋, 플러그인, 광고·결제, Supabase의 범위는 구현 계획과 관련 결정 ID로 제한한다.

## 이번 결과물

- [`QUIRKY_TOWER_REBOOT_MASTER_SPEC.html`](QUIRKY_TOWER_REBOOT_MASTER_SPEC.html): 사람이 검토하는 상세 시각 명세
- [`reboot_spec.css`](reboot_spec.css), [`reboot_spec.js`](reboot_spec.js): Master HTML의 로컬 공용 표현·탐색 자산. 외부 CDN·빌드 없음
- [`DECISION_REGISTER.md`](DECISION_REGISTER.md): 짧은 결정 정본
- [`FEATURE_TEST_MAP.md`](FEATURE_TEST_MAP.md): 요구사항과 검증 종류의 연결표
- 이 파일: 현재·다음·미검증만 유지하는 재개 지점

## 확정된 큰 방향

- 세 콘텐츠는 별도 미니게임이 아니라 한 런의 3막이다.
- 리더 한 마리를 직접 움직이고 이름 있는 동료는 최대 다섯 마리다.
- 드래그·스와이프·손 떼기만 사용한다.
- 오리·거위·닭·까마귀·비둘기를 기본 조류군으로 사용한다. `치킨`의 닭 전설 각성·코스튬 처리는 검토 후보다.
- Project K의 최근 카툰 애니풍 제작 규칙은 계승하지만 팔레트·세계관·현행 3D는 복제하지 않는다.
- 2D·3D·프로필·테두리·상점 에셋은 같은 안정 ID에서 파생한다.
- Pay-to-win을 허용하며 광고 완료와 결제는 같은 티켓 한 단위·효과·확률을 쓴다. 일일 획득량 동등은 아직 확정하지 않았다.
- 부스트 사용자를 별도 랭킹으로 나누지 않는다.
- 실제 국가와 유머성 소속은 하나의 사용자 선택 `국가/소속` 카테고리다.
- Supabase와 네이티브 수익화 SDK는 재미 게이트 이후다.
- Cloud는 코드·문서·분석, Local은 Godot·물리·UI·오디오·빌드에 사용한다.

## 아직 검토가 필요한 구체화

- 방송탑의 비밀, 구역 3개, 마스코트 `삐약 PD`라는 이야기 초안
- 조류별 세 막 역할과 닭의 전설 각성 구조
- 70~80초 구역, 4분 30초~5분 30초 런 페이싱
- `Sponsor Ticket` 이름과 시작 알·3택 재추첨·실패 막 재도전 사용처
- Tower 전용 남청·망고·청록·코럴·라일락 팔레트
- 112 BPM·16마디·4스템 오디오 기준
- 현재 upstream 일치 v0.7.2를 유지하고 upstream v0.8.0은 별도 diff·Godot 4.7 QA 뒤 갱신 여부를 판단하는 안
- 파일 크기 경고·차단 수치

세부 항목은 [`DECISION_REGISTER.md`](DECISION_REGISTER.md)의 `PROPOSED`와 `NEEDS_PLAYTEST` 상태로 표시했다. Gate A 구현 승인도 후보 수치나 손맛 판단을 `LOCKED`로 바꾸지 않는다.

## 다음 P0

[`Gate A 90초 greybox 계획`](../../.superpowers/sdd/2026-08-11-gate-a-90s-greybox/)을 실행한다.

> 오리·거위·비둘기, 한 구역, 세 막, 랜덤 3택 한 번을 포함한 90초 greybox.

그 계획은 기존 dirty `main`을 보호하는 `codex/*` worktree에서 TDD로 실행한다. 코드·정적 검사는 Cloud, Godot 4.7 CLI가 필요한 HEADLESS와 실제 충돌·터치·전환은 동일 CLI가 Cloud에 없으면 Local에서 한 번에 검증한다.

## 미검증

- 새 게임은 아직 구현되지 않았다.
- 새로운 3막을 실제 손가락으로 플레이하지 않았다.
- 새 스토리, 마스코트, 팔레트, 조류 역할을 사용자 화면으로 보지 않았다.
- 새 캐릭터 2D·3D·프로필·상점 자산을 만들지 않았다.
- 새 오디오를 작곡·청음하지 않았다.
- Sponsor Ticket 경제나 광고·결제 SDK를 구현하지 않았다.
- Android/iOS 성능, safe area, 햅틱, 오디오, 광고, 결제, 랭킹을 검증하지 않았다.
- 현재 기존 headless PASS는 폐기 대상 15층 코어의 증거이며 새 게임의 재미나 동작을 증명하지 않는다.

## 보호 중인 기존 변경

작성 시작 시 다음 변경은 공통 테스트 기준 이관 작업으로 확인했다. 이 리부트 명세 작업의 소유가 아니므로 stage·commit·되돌리기·덮어쓰기를 금지한다.

- `M docs/canonical/README.md`
- `M docs/canonical/design_policy.md`
- `D docs/canonical/house_duck_test_case_standard.md`
- `M docs/canonical/qa.md`

## 재개 절차

1. `git status --short --branch`와 현재 브랜치·원격 차이를 확인한다.
2. 이 파일과 [`DECISION_REGISTER.md`](DECISION_REGISTER.md)를 읽는다.
3. 작업할 기능의 HTML 섹션 하나와 [`FEATURE_TEST_MAP.md`](FEATURE_TEST_MAP.md) 행만 읽는다.
4. 관련 기존 코드의 호출 흐름을 확인한다.
5. 한 vertical slice와 한 최소 검증만 계획한다.
6. 엔진이 필요 없으면 Godot를 열지 않는다.
7. Local 검증을 했다면 에이전트가 시작한 정확한 PID와 포트만 종료한다.
8. 변경 파일만 stage·commit·push하고 미검증을 분리해 보고한다.

## 문서 성장 규칙

- 이 파일은 200줄·20KiB를 넘기지 않는다.
- 완료 항목은 누적하지 않고 Git commit과 history 문서로 이동한다.
- 현재 단계가 바뀌면 “지금 무엇인가 / 다음 P0 / 미검증 / 재개 절차”만 갱신한다.
- 채팅 요약보다 이 파일과 decision ID를 우선한다.
