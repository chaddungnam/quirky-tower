# Quirky Tower Reboot Decision Register

상태: **Approved for Gate A implementation**
기준일: **2026-08-11**
대상: 기존 15층 미니게임 프로토타입을 조류단 3막 로그라이트 액션으로 교체하는 리부트
시각 검토본: [`QUIRKY_TOWER_REBOOT_MASTER_SPEC.html`](QUIRKY_TOWER_REBOOT_MASTER_SPEC.html)

이 파일은 리부트 작업의 짧은 결정 정본이다. 채팅 기억이나 HTML 설명이 이 표와 충돌하면 구현을 멈추고 이 표를 먼저 고친다. `LOCKED`는 사용자가 대화에서 승인한 범위, `PROPOSED`는 이번 검토본의 구체화, `NEEDS_PLAYTEST`는 사람 손맛 검증 전 확정 금지, `DEFERRED`는 후속 마일스톤, `CUT`은 새 코어에서 제거할 범위다.

## 읽기 순서

1. 이 결정표
2. [`WORK_STATE.md`](WORK_STATE.md)
3. 현재 작업과 관련된 HTML 섹션 한 곳
4. [`FEATURE_TEST_MAP.md`](FEATURE_TEST_MAP.md)의 대응 테스트
5. 구현 계획과 코드

## 제품과 코어

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-PROD-001` | `LOCKED` | 기존 `Timing Ring → Tap Panic → Drag Dodge` 순환을 폐기하고 조류단 로그라이트 액션으로 재구축한다. | 세 게임이 한 런으로 느껴지지 않았고 인과와 재미를 설명하지 못했다. |
| `QT-RB-PROD-002` | `LOCKED` | 한 줄 정의는 “오리 리더가 최대 다섯 동료를 모아 피하고, 들이받고, 약점을 연결해 방송탑을 연쇄 붕괴시키는 세로형 운빨 액션”이다. | 첫 10초에 조작과 목표가 함께 읽혀야 한다. |
| `QT-RB-GAME-001` | `LOCKED` | `조류단 진입 → 옥상 난투 → 깃털 사슬 습격 → 랜덤 3택`을 한 구역 안에서 로딩 없이 연결한다. | 세 재미를 따로 메뉴화하지 않는다. |
| `QT-RB-GAME-002` | `LOCKED` | 직접 조작 대상은 리더 한 마리, 이름 있는 동료는 최대 다섯 마리다. | 한 손 조작과 캐릭터 애착을 동시에 유지한다. |
| `QT-RB-GAME-003` | `LOCKED` | 리더·동료·체력·콤보·빌드·시드는 세 막 사이에 그대로 이어진다. | 미니게임 묶음이 아닌 하나의 사건으로 느껴져야 한다. |
| `QT-RB-GAME-004` | `LOCKED` | 인게임 제스처는 드래그, 짧은 스와이프, 손 떼기로 제한한다. 가상 조이스틱과 다수 액션 버튼은 쓰지 않는다. | Quirky Ball 수준의 낮은 진입 난도를 지킨다. |
| `QT-RB-GAME-005` | `PROPOSED` | 한 구역 목표는 70~80초, 세 구역과 최종 송출실을 포함한 한 런 목표는 4분 30초~5분 30초다. | 숫자는 구현 계약이 아니라 초기 페이싱 목표이며 플레이테스트로 조정한다. |
| `QT-RB-GAME-006` | `LOCKED` | 구역 종료 3택은 세로 카드로 노출하고 선택 결과는 최소 두 막, 가능하면 세 막 모두에 영향을 준다. | 선택이 다음 미니게임 하나에만 묶이면 빌드 감각이 끊긴다. |
| `QT-RB-GAME-007` | `PROPOSED` | 진입은 위험·구조·보상 경로 선택, 난투는 방향성 대시와 환경 충돌, 사슬 습격은 경로 그리기 후 일제 돌진으로 구성한다. | 같은 무리를 다른 감각으로 쓰되 입력 문법은 유지한다. |
| `QT-RB-GAME-008` | `LOCKED` | 카타르시스는 실제 충돌 → 균열 → 부품 이탈 → 층 붕괴 → 보상 방출의 순서로 읽혀야 한다. 화면 흔들기와 큰 숫자만으로 대체하지 않는다. | 플레이어가 자신이 무엇을 부쉈는지 알아야 한다. |
| `QT-RB-GAME-009` | `PROPOSED` | 최종 송출실은 새로운 네 번째 규칙을 추가하지 않고 앞의 세 막을 더 짧고 크게 조합한다. | 마지막에 학습 비용을 늘리지 않고 숙련을 폭발시킨다. |
| `QT-RB-GAME-010` | `NEEDS_PLAYTEST` | 합성은 같은 동료 중복 획득 시 자동 후보가 되며, 정확한 필요 수와 등급 상한은 90초 슬라이스 이후 확정한다. | 숫자 게이트가 재미를 앞서지 않게 한다. |
| `QT-RB-GAME-011` | `NEEDS_PLAYTEST` | 체력, 대시 쿨다운, 경직, 적 수, 연쇄 배수, 선택 가중치는 사람 플레이 증거 없이 잠그지 않는다. | 헤드리스 완주율은 손맛을 증명하지 않는다. |
| `QT-RB-GAME-012` | `PROPOSED` | 한 active pointer는 현재 막의 `InputRouter` 하나만 소유한다. 진입·난투에서는 drag를 기본으로 하고 release 거리·속도 문턱을 넘을 때만 대시로 판정한다. 사슬 진입·팝업·focus loss 때 기존 gesture를 취소하고 새 touch부터 받는다. | 이동 release가 다음 막의 사슬 공격이나 유령 대시로 바뀌는 일을 막는다. 정확한 문턱은 사람 플레이로 조정한다. |
| `QT-RB-GAME-013` | `PROPOSED` | 실패 막 재도전은 막 시작의 체력·조류단·빌드·적 배치·붕괴 원장·gameplay RNG 상태를 하나의 snapshot으로 복원한다. 광고 callback은 RNG를 진행하지 않으며 `retry_count`와 모든 시도의 active time은 snapshot 밖 기록에 누적한다. | 재도전, checksum, 타임어택을 같은 규칙으로 재현한다. |

## 조류, 이야기, 마스코트

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-CAST-001` | `LOCKED` | 기본 세계관은 오리·거위·닭·까마귀·비둘기를 중심으로 한다. | House Duck 정체성과 조류 실루엣 다양성을 함께 쓴다. |
| `QT-RB-CAST-002` | `PROPOSED` | 오리는 지휘·균형, 거위는 방어·중량, 닭은 속도·연속, 까마귀는 위험 보상·약점, 비둘기는 경로 보정·와일드카드 역할을 맡는다. | 모든 종이 세 막에서 서로 다른 쓸모를 가져야 한다. |
| `QT-RB-CAST-003` | `PROPOSED` | `치킨`은 별도 생물 종이 아니라 닭의 전설 각성 또는 코스튬 계열로 사용한다. | 농담을 살리면서 캐릭터 분류를 늘리지 않는다. |
| `QT-RB-CAST-004` | `LOCKED` | 동료는 숫자 토큰이 아니라 이름, 성격, 대표색, 소품, 짧은 반응 대사를 가진다. | 런 중 구조와 상실에 감정적 의미를 준다. |
| `QT-RB-CAST-005` | `PROPOSED` | Gate B 전에 기본 종마다 첫 동료 한 명의 `display_name_key`, 성격 태그, 대표색, 소품 ID, 구조·충돌·성공·실패 반응을 승인한다. | 종 역할만 정한 상태를 “이름 있는 동료 완료”로 오인하지 않는다. |
| `QT-RB-STORY-001` | `PROPOSED` | 겉으로는 “행운의 새를 뽑는 생방송”인 타워가 조류 집단을 경쟁시키고 응원 에너지를 빼앗는다는 비밀을 세 구역에서 드러낸다. 리더의 목표는 실종 동료 구조와 최종 방송 탈취다. | 별도 장문 컷신 없이 플레이 행동 자체가 이야기 원인이 된다. |
| `QT-RB-STORY-002` | `PROPOSED` | 구역 1은 비둘기 배달층과 조작된 예선, 구역 2는 닭 가공 무대와 거위 경비대, 구역 3은 까마귀 기록보관소와 방송 조작 증거, 최종은 송출실 탈취다. | 종족 소개, 구조, 세계관 폭로를 같은 동선에 묶는다. |
| `QT-RB-STORY-003` | `LOCKED` | 긴 설명 화면 대신 환경 변화, 1문장 말풍선, 짧은 방송 자막, 구역 종료 한 비트로 전달한다. | 플레이 흐름을 멈추지 않는다. |
| `QT-RB-STORY-004` | `PROPOSED` | 각 런은 시간 되감기가 아니라 타워의 다음 생방송 회차다. 실패·완주 뒤 구조 후보와 편성이 바뀌고, 메타 진행은 확보한 방송 증거와 구조 명단으로 설명한다. | 반복 런과 로그라이트 메타가 이야기 안에서도 자연스럽게 이어진다. |
| `QT-RB-MASCOT-001` | `PROPOSED` | 마스코트는 타워에서 이탈한 병아리 카메라 조수 `삐약 PD`다. 다음 행동 하나만 알려주고 성공·실패에 몸짓으로 반응한다. | 도움말과 이야기 전달자를 한 캐릭터로 합친다. 이름은 원화·말투 검토에서 교체 가능하다. |
| `QT-RB-MASCOT-002` | `LOCKED` | 마스코트 말풍선은 최대 한 문장·두 줄, 위험 중 전면 팝업 금지, 시스템 결과와 같은 말을 반복하지 않는다. | 화면을 가리거나 장황해지는 문제를 막는다. |

## 아트와 에셋

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-ART-001` | `LOCKED` | Project K 최신 카툰 애니풍의 큰 실루엣, 좌상단 단일 주광원, 한 단계 원톤 그림자, 정리된 픽셀 경계를 계승한다. | 같은 회사의 제작 언어는 유지하되 세계관은 분리한다. |
| `QT-RB-ART-002` | `LOCKED` | Project K의 적갈·올리브 선전 팔레트, 군복, 독재국·AI기업 세계관, 현재 절차형 박스 3D는 가져오지 않는다. | 복제와 분위기 충돌을 막는다. |
| `QT-RB-ART-003` | `LOCKED` | 2D 전신, 대화 크롭, 프로필, 카드, 상점 썸네일, 3D 모델은 같은 `character_id`, 체형, 복장선, 대표색을 공유한다. | 한 캐릭터가 화면마다 달라 보이지 않게 한다. |
| `QT-RB-ART-004` | `PROPOSED` | 2D 원본은 400×800 전신과 표정 4종을 기본으로 하고, 프로필·대화·상점은 원본을 crop·scale해 파생한다. | 중복 원화 생산을 줄인다. |
| `QT-RB-ART-005` | `LOCKED` | 3D는 2D를 자동 변환하지 않고 동일 턴어라운드를 기준으로 별도 저폴리 모델링한다. 실제 콜라이더를 사용한다. | 인게임 실루엣과 물리 원인을 둘 다 보장한다. |
| `QT-RB-ART-006` | `PROPOSED` | 인게임은 저폴리 3D 몸체, nearest 필터의 2D 픽셀 얼굴·표면 재질, 저해상도 월드 데칼을 결합한다. | 사용자가 요청한 Godot 기본 3D와 2D 픽셀 표면을 결합한다. |
| `QT-RB-ART-007` | `LOCKED` | 프로필·상점 희귀도 테두리는 공용 frame set을 재사용하고 캐릭터별로 복제하지 않는다. | 상점·도감 에셋 양산 비용을 줄인다. |
| `QT-RB-ART-008` | `PROPOSED` | 첫 아트 게이트는 오리 1종의 2D 턴어라운드, 3D 모델, 프로필, 상점 카드, 실루엣 비교를 한 번에 통과시키는 것이다. | 파이프라인 승인 전에 전체 조류를 만들지 않는다. |
| `QT-RB-ART-009` | `DEFERRED` | 닭·까마귀·치킨을 포함한 전체 상점 에셋 양산은 90초 재미 게이트 이후다. | 재미없는 게임의 상품 이미지를 먼저 만들지 않는다. |
| `QT-RB-ART-010` | `PROPOSED` | Tower 전용 팔레트는 밤 남청, 망고 노랑, 청록, 코럴, 라일락을 역할색으로 사용한다. 참고 스크린샷의 청록 SF 프레임은 그대로 복제하지 않는다. | Quirky Ball과 Project K 모두와 다른 방송 사고·옥상 활극 인상을 만든다. |
| `QT-RB-ART-011` | `PROPOSED` | 첫 frame set의 등급 이름은 `common/rare/epic/legendary` 4종으로 검토한다. | 이름과 수량은 경제 등급 구조 승인 전 바뀔 수 있다. |
| `QT-RB-ART-012` | `PROPOSED` | 400×800 2D 마스터에서 프로필 1:1, 대화 crop, 상점 캐릭터 3:4를 비파괴 파생하고 번역 텍스트·frame은 별도 UI/NinePatch 레이어로 합성한다. 오리 게이트에서 얼굴·부리·소품 safe area를 잠근다. | 재생성으로 캐릭터 얼굴이 달라지거나 번역이 이미지에 굽는 일을 막는다. |
| `QT-RB-ART-013` | `PROPOSED` | 2D·3D는 `idle/locomotion/dash/hit/rescued/chain_windup/chain_attack/success/failure/shop_pose` 공통 animation ID를 사용한다. | 빠진 동작을 임의의 다른 애니메이션으로 대체하지 않고 파생 자산을 추적한다. |

## UI, 화면, 다국어

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-UI-001` | `LOCKED` | 논리 UI 기준은 720×1280로 유지한다. 기본 실행·캡처는 1080×2400 FHD+ 20:9이며 `canvas_items/expand`가 세로 추가 영역을 제공한다. HUD·핵심 CTA의 720×1280 safe frame은 root layout에서 명시적으로 가운데 정렬하고 720×1600을 새 자산 기준으로 재정의하지 않는다. | 기존 좌표·HUD 계약을 보존하면서 20:9 전체 화면을 쓴다. |
| `QT-RB-UI-002` | `LOCKED` | 색, 간격, 반경, 글자, 모션은 `AppTheme`와 `DesignTokens`에서 바꾸면 모든 화면에 전파되어야 한다. | 화면별 상수 복제를 금지한다. |
| `QT-RB-UI-003` | `LOCKED` | 팝업·언어·강화 3택·결과의 선택 행동은 항상 세로 `VBoxContainer`에 배치한다. | 독일어·아랍어 등 길이 변화에 가로 선택열이 깨지는 일을 막는다. |
| `QT-RB-UI-004` | `LOCKED` | 화면은 배경 → 주체 → 맥락 → 행동 순으로 등장하고, 결과는 파괴 → 보상 카운트 → 마스코트 → 다음 행동 순으로 보여준다. | 딱딱한 시작·결과 화면을 없앤다. |
| `QT-RB-UI-005` | `LOCKED` | 인게임 장문 설명, 같은 뜻의 배너·말풍선 중복, 원인을 가리는 파티클, gratuitous 회전 애니메이션을 금지한다. | 플레이 중 읽기 부담과 시각 잡음을 줄인다. |
| `QT-RB-UI-006` | `LOCKED` | `ko/en/de/ja/fr/es/it/zh_CN/zh_TW/ar`와 영어 fallback을 유지한다. KO·EN·DE·JA·AR은 필수 레이아웃 스트레스 언어다. | 기존 공통 기반을 살린다. |
| `QT-RB-UI-007` | `PROPOSED` | 홈·설정·도감·프로필·상점·랭킹은 앱 셸을 재사용하되 리부트 인게임이 통과하기 전에는 mock data만 사용한다. | Supabase와 SDK를 선행하지 않는다. |
| `QT-RB-UI-008` | `LOCKED` | Reduce Motion에서도 상태는 색, 외곽선, 위치, 크기 변화로 전달하고 흔들기·플래시만 제거한다. | 접근성 때문에 피드백 자체가 사라지면 안 된다. |
| `QT-RB-UI-009` | `PROPOSED` | 선택 버튼은 최소 96 logical px, 기본 설명은 두 줄, 본문만 scroll, CTA ellipsis 금지를 첫 토큰값으로 검토한다. | 정확한 수치는 20:9·다국어·실기기 터치에서 조정한다. |
| `QT-RB-UI-010` | `PROPOSED` | 화면 요소 간 70~120ms, 전체 420ms 이내, 충돌 hit stop 40~70ms를 첫 모션값으로 검토한다. | 순서는 승인됐지만 정확한 시간은 눈으로 검증해야 한다. |
| `QT-RB-UI-011` | `PROPOSED` | modal owner는 하나이며 popup은 gameplay freeze, 본문만 scroll, 세로 행동, 첫 유효 입력 뒤 잠금, dismiss·뒤로가기 정책을 명시한다. locale 변경 중 callback을 중복 연결하지 않는다. | 팝업 뒤 유령 입력·이중 보상·뒤로가기 혼선을 막는다. |
| `QT-RB-UI-012` | `PROPOSED` | 앱 배너·홈·런 준비·HUD·일시정지·결과·설정·도감·프로필·상점·랭킹·국가/소속은 각각 진입 조건, 표시 데이터, 주·보조 CTA, back, empty/loading/error, 데이터 출처, safe area 계약을 가진다. | 화면 이름만 있고 상태 계약이 없는 명세를 막는다. |
| `QT-RB-UI-013` | `PROPOSED` | 아랍어는 RTL layout direction을 적용하되 점수·시간 숫자와 방향 의미가 고정된 아이콘은 자동 미러링하지 않는다. | 단순 overflow 검사만으로 RTL 완료를 주장하지 않는다. |

## 오디오와 햅틱

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-AUDIO-001` | `LOCKED` | House Duck 공통 취향인 베이스·킥 우선, 화성 일치, 길이·강약·쉼 변화, 독립적인 고음 삑삑 리드 금지를 적용한다. | Project K에서 이미 확인한 불쾌 요소를 반복하지 않는다. |
| `QT-RB-AUDIO-002` | `PROPOSED` | Godot 기본 버스 `Master/Music/SFX/UI/Voice`와 동기화된 `core/movement/danger/jackpot` 4스템을 사용한다. | 외부 미들웨어 없이 세 막을 끊김 없이 전환한다. |
| `QT-RB-AUDIO-003` | `PROPOSED` | 112 BPM, 4/4, 16마디 루프를 첫 작곡 기준으로 삼고 스템 전환은 다음 마디에서 한다. | 7~8초 반복 피로와 위상 어긋남을 피한다. BPM은 청음에서 변경 가능하다. |
| `QT-RB-AUDIO-004` | `LOCKED` | 충돌·연결·붕괴·보상은 즉시 SFX, 막 전환은 스템, 구역 완료는 짧은 스팅어로 분리한다. | 행동과 음악 상태 변화의 역할을 섞지 않는다. |
| `QT-RB-AUDIO-005` | `LOCKED` | 자동 수치 PASS와 macOS/Android/iOS 스피커·이어폰 청음은 별도 증거다. | 수치가 취향과 실제 기기 소리를 대신하지 않는다. |
| `QT-RB-HAPTIC-001` | `PROPOSED` | 탭, 근접 회피, 대시 충돌, 연쇄 붕괴, 보상에 서로 다른 짧은 패턴을 쓰고 120ms 안의 중복 진동은 합친다. | 지속 진동과 피로를 막는다. |

## BM, 랭킹, 소속

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-BM-001` | `LOCKED` | Pay-to-win 효과를 허용한다. 보상형 광고 완료와 결제는 같은 `Sponsor Ticket` 한 단위를 지급하며 item ID·효과·확률·seed 처리·checksum이 동일하다. 단위 동등성은 일일 획득량 동등을 뜻하지 않으며 광고 상한·판매량은 별도 후보로 둔다. | 광고를 본 사용자는 구매자와 같은 한 번의 효과를 얻고, P2W 승인과도 모순되지 않는다. |
| `QT-RB-BM-002` | `PROPOSED` | 단일 소모품 이름은 `Sponsor Ticket`이며 시작 알 강화, 3택 재추첨, 실패 막 1회 재도전에 사용한다. | 광고용·유료용 아이템을 분리하지 않는다. |
| `QT-RB-BM-003` | `LOCKED` | 광고·결제 출처는 분석 원장에만 기록하고 런 판정과 아이템 성능에는 사용하지 않는다. | 동일 아이템 계약을 지킨다. |
| `QT-RB-BM-004` | `LOCKED` | 부스트 사용 여부로 공식·비공식 랭킹을 나누지 않는다. 모든 정상 런은 같은 랭킹에 들어간다. | 사용자 결정대로 랭킹을 파편화하지 않는다. |
| `QT-RB-BM-005` | `LOCKED` | 글로벌, 친구, 타임어택, 국가/소속은 같은 정상 런 기록 풀을 보는 경쟁 보기다. | 지원 출처별 공식·비공식 풀을 만들지 않는다. 보기별 정렬 계약은 별도 결정한다. |
| `QT-RB-BM-006` | `LOCKED` | 실제 국가와 유머성 소속은 사용자가 고르는 하나의 `affiliation_code` 목록이다. UI 명칭은 `국가/소속`이다. | 두 범주를 분리하거나 자동 추정하지 않는다. |
| `QT-RB-BM-007` | `PROPOSED` | 첫 상점은 티켓 묶음, 스킨, 프로필, 공용 희귀도 프레임, 스타터 팩만 사용한다. 유료 랜덤 상자는 넣지 않는다. | 수익 구조는 확보하되 첫 출시 경제를 단순하게 둔다. |
| `QT-RB-BM-008` | `DEFERRED` | 시즌 패스, 유료 캐릭터 가챠, 복잡한 재화, 라이브 이벤트 상점은 D1/D7·광고 지표 이후 판단한다. | 출시 전 운영 시스템 과투자를 막는다. |
| `QT-RB-BM-009` | `PROPOSED` | 전면 광고는 첫 2런을 면제하고 런 종료 뒤에만, 최소 8분 간격으로 검토한다. 최근 120초 안에 보상형 광고를 마쳤으면 생략하며 인게임과 선택 직전·직후 배너는 금지한다. | 흐름과 재시도를 해치지 않는다. 정확한 간격은 실제 지표 뒤 조정한다. |
| `QT-RB-BM-010` | `NEEDS_PLAYTEST` | 광고 일일 상한, 티켓 가격, 부스트 수치, 부활 위치는 재미·경제 시뮬레이션과 실제 광고 지표 뒤에 확정한다. | 수익 목표를 이유로 조작감을 선결정하지 않는다. |
| `QT-RB-BM-011` | `PROPOSED` | 점수 보기는 score 내림차순, 타임어택은 완주 기록만 모든 시도의 active gameplay time 오름차순으로 정렬한다. 동률은 score 내림차순 뒤 `run_id`로 고정하고 pause·선택·광고·background 시간은 제외한다. | 같은 record를 쓰면서 타임어택의 경쟁값과 재도전 처리도 재현 가능하게 만든다. |
| `QT-RB-BM-012` | `PROPOSED` | 랭킹 제출 시 `affiliation_code` snapshot을 기록한다. 이후 소속 변경은 과거 기록을 옮기지 않고 새 기록부터 적용한다. | 소속을 바꿔 기존 랭킹을 이동시키는 혼선을 막는다. |

## 기술, 플러그인, 작업 운영

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-TECH-001` | `LOCKED` | Godot 4.7, GDScript, 고정 직교 사선 `Camera3D`, 기본 3D 물리와 실제 콜라이더를 우선한다. | 이미 설치된 엔진 기능으로 충분하다. |
| `QT-RB-TECH-002` | `LOCKED` | 순수 시드 기반 규칙 코어는 scene Node, UI, 광고, 결제, Supabase를 참조하지 않는다. GDScript HEADLESS도 Godot 4.7 실행파일이 필요하므로 Cloud에 같은 CLI가 있을 때만 Cloud에서 돌리고, 없으면 Local CLI에서 한 번에 돌린다. | 규칙과 월드를 분리하되 엔진 없는 Cloud PASS를 주장하지 않는다. |
| `QT-RB-TECH-003` | `PROPOSED` | 3막 전환은 enum과 signal로 구현하고 상태차트·행동트리 플러그인을 쓰지 않는다. | 상태 수가 적어 기본 기능이 더 작고 명확하다. |
| `QT-RB-TECH-004` | `PROPOSED` | 붕괴는 완전한 실시간 파괴가 아니라 미리 나눈 조각과 실제 충돌 트리거를 조합한 authored destruction으로 구현한다. | 모바일 성능과 재현성을 유지하면서 원인은 실제 충돌로 남긴다. |
| `QT-RB-TECH-005` | `PROPOSED` | 저장은 stable `run_id`, schema version, 순차 migration, one-shot reward ledger를 사용한다. 손상 상태는 crash·중복 보상 없이 해당 복원만 포기하고 안전한 화면으로 종료한다. | 저장 복구와 보상 무결성을 같은 계약으로 검증한다. |
| `QT-RB-TECH-006` | `PROPOSED` | 목표 저사양 Android를 정한 뒤 60fps와 최악 장면 p95 frame time≤16.7ms를 첫 성능 gate로 검토한다. | 60fps와 20ms의 수학적 모순을 없애고 실제 기기에서만 확정한다. |
| `QT-RB-TECH-007` | `PROPOSED` | Godot 3D physics는 deterministic하지 않으므로 replay checksum은 조우·3택·지원 효과·이산 event ledger에만 적용한다. 접촉점·trajectory·RigidBody timing·최종 위치는 checksum과 서버 재시뮬레이션 근거에서 제외한다. | 시드 재현성을 물리 재현성으로 과장하지 않는다. |
| `QT-RB-PLUGIN-001` | `LOCKED` | 현재 개발 플러그인은 `Godot MCP/CLI` 하나만 둔다. Context7와 중복 MCP는 사용하지 않는다. | 무료 로컬 문서와 live ClassDB로 문맥 비용을 낮춘다. |
| `QT-RB-PLUGIN-002` | `PROPOSED` | MIT 라이선스 upstream과 EOL을 정규화하면 내용 차이 0인 v0.7.2를 유지한다. v0.8.0 갱신은 구현 Phase 0 별도 브랜치에서 diff·Godot 4.7 QA를 통과하고 당시 Asset Library 등록도 다시 본다. | Asset Library 등록은 Godot 팀 제작을 뜻하지 않는다. 자동 갱신과 불필요한 downgrade를 모두 피한다. |
| `QT-RB-PLUGIN-003` | `LOCKED` | 모든 release preset에서 MCP를 비활성화하고 autoload 2개 부재, `addons/godot_mcp/*` exclude, PCK의 addon·server 문자열 부재를 검사한다. 현재 `export_presets.cfg`가 없으므로 preset 생성 시 이 gate를 함께 만든다. | 개발 서버가 제품에 포함되면 안 된다. |
| `QT-RB-PLUGIN-004` | `DEFERRED` | AdMob, Play Billing, StoreKit, Supabase, 분석 SDK는 각 후속 게이트에서 원본·라이선스·4.7 호환을 재검증한 뒤 설치한다. | 재미 검증 전에 런타임 의존성을 늘리지 않는다. |
| `QT-RB-PLUGIN-005` | `CUT` | GUT/GdUnit4, Phantom Camera, State Charts, Dialogic, Terrain/Scatter, FMOD/Wwise는 현재 범위에서 사용하지 않는다. | 기존 headless QA와 Godot 기본 기능이 요구를 충족한다. |
| `QT-RB-SKILL-001` | `PROPOSED` | `brainstorming → 서면 spec·self-review → 사용자 spec 승인 → writing-plans → worktree/TDD → 독립 구현·리뷰 → Local Godot → verification-before-completion` 순서를 사용한다. | 장기 작업의 핀트와 증거 경계를 지킨다. |
| `QT-RB-SKILL-002` | `PROPOSED` | Ponytail full을 적용해 기존 코드 → 표준 기능 → Godot 기본 → 설치된 의존성 → 최소 신규 코드 순서로 선택한다. | 한 달 목표에 맞춰 과설계를 막는다. |
| `QT-RB-SKILL-003` | `PROPOSED` | `imagegen`은 승인된 마스터 원화 후보, `humanize-pixel-game-ui`는 픽셀 표면·UI 모션 QA, `godot-local-docs`는 4.7 API, `godot-mcp`는 Local 런타임에만 사용한다. | 한 스킬이 다른 역할을 흉내 내지 않게 한다. |
| `QT-RB-OPS-001` | `LOCKED` | GitHub가 Cloud와 Local의 기준 상태이며 ZIP·수동 파일 전달을 사용하지 않는다. | 사용자 개입과 상태 유실을 줄인다. |
| `QT-RB-OPS-002` | `LOCKED` | 코드·분석·문서는 Cloud 우선, Godot·물리·UI·오디오·빌드·실기기는 Local에서 의미 있는 게이트마다 한 번에 검증한다. | MacBook Air M2 부하와 왕복을 줄인다. |
| `QT-RB-OPS-003` | `LOCKED` | 에이전트가 시작한 Godot·MCP·adb·Gradle·lldb 프로세스만 정확한 PID로 종료하고 광범위한 `pkill`은 금지한다. | 사용자 프로세스를 보존하고 메모리를 회수한다. |

## 문서, 파일 크기, 컨텍스트

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-DOC-001` | `LOCKED` | Git 문서가 정본이며 채팅, 메모리, 스크린샷은 보조 증거다. | 세션이 길어져도 결정이 흔들리지 않게 한다. |
| `QT-RB-DOC-002` | `LOCKED` | `WORK_STATE.md`는 200줄·20KiB 이하로 현재·다음·미검증만 유지하고 완료 이력은 Git과 history로 보낸다. | Project K의 누적형 거대 work state를 반복하지 않는다. |
| `QT-RB-DOC-003` | `PROPOSED` | `.gd`는 500줄 경고·800줄 차단, `.md/.json`은 600줄 또는 60KiB(61,440 bytes) 경고·1,200줄 또는 120KiB(122,880 bytes) 차단, HTML은 120KiB 경고·180KiB 차단을 기본 gate로 둔다. 현재 검사기는 이 전체 규칙을 아직 강제하지 않는다. | 숫자만으로 기계 분리하지 않되 구현 전후 성장 신호를 자동으로 잡는다. |
| `QT-RB-DOC-004` | `LOCKED` | 기능은 결정 ID와 테스트 ID를 함께 가져야 하고, 계획은 전체 명세 복사 대신 필요한 ID와 파일만 참조한다. | 저토큰으로도 요구와 검증을 잃지 않는다. |
| `QT-RB-DOC-005` | `PROPOSED` | HTML이 120KiB를 넘으면 공유 CSS/JS, 섹션 HTML, `index.html`로 분리한다. 빌드 도구 없이 정적 파일로 열 수 있어야 한다. | 문서 로직을 복제하지 않고 단순 파일 구조를 유지한다. |
| `QT-RB-DOC-006` | `LOCKED` | 이 리부트 4개 문서는 Gate A 구현 승인 정본이다. 기존 `docs/canonical/*`의 15층·Timing Ring 도메인은 legacy 근거이며 새 코어 정본이 아니다. 관련 canonical은 결정 ID 기준으로 갱신한다. | 구정본을 새 구현 요구로 잘못 읽는 일을 막는다. |

## 분석과 측정

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-ANALYTICS-001` | `PROPOSED` | 필수 이벤트는 run·district·act·build·support·광고·구매·랭킹·소속의 상태 전이만 보낸다. 광고는 offer/start/complete/cancel/fail/no_fill, 구매는 start/complete/cancel/fail/restore를 구분하고 모든 touch·frame 위치·GPS 기반 소속은 보내지 않는다. | 재미·BM 원인을 보되 payload와 개인정보를 늘리지 않는다. |
| `QT-RB-ANALYTICS-002` | `PROPOSED` | 첫 런 결과는 성공·실패 어느 쪽이든 `run_end` 도달로 정의한다. D1은 설치 24~48시간, D7은 144~192시간 내 세션으로 계산하고 완전한 관찰 기간 전 수치는 방향성으로만 표시한다. | retention 목표의 cohort와 시간창을 고정한다. |
| `QT-RB-ANALYTICS-003` | `PROPOSED` | 첫 런 결과 도달 80%+, 두 번째 런 시작 45%, D1 25% 최소·30% 목표, D7 8% 최소·10~12% 목표를 내부 가설로 둔다. 시장 평균이나 출시 보장은 아니다. | 수치가 목적이 아니라 확장 중단 신호로 작동하게 한다. |

## QA와 출시 게이트

| ID | 상태 | 결정 | 이유·영향 |
|---|---|---|---|
| `QT-RB-QA-001` | `LOCKED` | headless, Godot runtime, GUI 관찰, 실기기, 사람 재미 증거는 서로 대체하지 않는다. | 자동 PASS를 손맛·출시 증명으로 확대하지 않는다. |
| `QT-RB-QA-002` | `PROPOSED` | 첫 구현 게이트는 오리·거위·비둘기, 한 구역, 3막, 3택 1회의 90초 greybox다. | 가장 작은 완전한 재미 고리를 먼저 본다. |
| `QT-RB-QA-003` | `PROPOSED` | greybox 통과 조건은 10초 안에 목표 이해, 충돌 원인 설명 가능, 3막 구분 가능, 5명 중 3명 이상 자발적 재도전이다. | 수치 자동화가 아닌 사람 관찰 기준을 둔다. |
| `QT-RB-QA-004` | `PROPOSED` | 다음 게이트는 세 구역+최종 송출실 5분 런, 그다음 오리 마스터 2D/3D+4스템, 그다음 outgame mock, 마지막 SDK/backend다. | Local 검증과 자산 투자를 묶어서 진행한다. |
| `QT-RB-QA-005` | `LOCKED` | 기존 앱 셸·공통 UI·메인 씬·종료 정리 테스트는 유지하고 기존 15층 도메인 결합 테스트는 새 3막 테스트로 교체한다. | 재사용 가능한 기반만 살린다. |
| `QT-RB-QA-006` | `LOCKED` | 완료 보고에는 변경 파일, 검증 종류, 미검증, Godot/실기기 필요 여부, branch, commit, push, 잔존 프로세스를 적는다. | 다음 작업자가 추측 없이 재개할 수 있게 한다. |
| `QT-RB-QA-007` | `LOCKED` | 화면 결과가 바뀌는 구현은 최종 코드에서 새로 만든 1080×2400 비포·애프터 캡처와 명세→구현→증거 대조표가 있어야 완료 후보가 된다. 코드 파싱·headless PASS만으로 Visual 또는 Human PASS를 선언하지 않는다. | House Duck 공통 검증 규칙과 사용자의 명세 승인 조건을 프로젝트 정본에 고정한다. |

## 명시적 폐기와 보류

### CUT

- 15층마다 세 미니게임을 번갈아 실행하는 메인 루프
- 기존 `ChallengeRules`, `RunEngine`, `RunSimulator`, `RunController`의 현재 도메인 규칙
- 기존 floors/challenges/quirks/story JSON 내용과 5·10·15층 고정 스토리
- 기존 Quirk 4종과 `Sponsor Boost = 하트 +1` 구체 효과
- 미니게임마다 별도 제목·점수·결과를 초기화하는 전환
- 설명문으로 충돌 원인을 보완하는 방식
- 저폴리 복도와 픽셀 진행자를 최종 에셋으로 간주하는 것

### KEEP

- `project.godot`의 메인 씬과 20:9 실행·stretch 기반
- 앱 시작 배너, 홈, 설정, 뒤로가기·팝업 freeze 기반
- `AppTheme`, `DesignTokens`, 세로 선택 팝업, 1회 입력 잠금, 등장 모션
- 마스코트 말풍선과 반응 모션 기반
- 10개 locale와 영어 fallback
- 원개발자 upstream Godot MCP 구조와 House Duck 프로세스 종료 규칙
- 고정 시드, 대량 밸런스 시뮬레이션, 광고·결제 효과 동등성 검사라는 테스트 기법
- 실제 콜라이더, 고정 사선 카메라, 2D 픽셀 표면이라는 기술 실험

### DEFERRED

- Supabase와 실제 랭킹 서버
- AdMob, Billing, StoreKit 실연동
- 전체 캐릭터·상점 에셋 양산
- 시즌 패스, 유료 가챠, 복잡한 재화
- Android/iOS 출시 빌드와 실제 기기 스토어 검증

## 변경 규칙

- `LOCKED` 변경은 사용자 승인과 새 근거를 함께 기록한다.
- 상태를 바꿀 때 기존 행을 조용히 덮지 말고 아래 변경 이력에 한 줄을 추가한다.
- 숫자 조정은 관련 `NEEDS_PLAYTEST` 행과 테스트 증거를 먼저 갱신한다.
- 충돌이 생기면 새 코드를 합리화하지 말고 결정·테스트·코드 중 어느 것이 잘못됐는지 분리한다.

## 변경 이력

| 날짜 | 변경 | 근거 |
|---|---|---|
| 2026-08-11 | 리부트 검토본 최초 작성. 대화에서 승인된 범위는 `LOCKED`, 새 구체화는 `PROPOSED/NEEDS_PLAYTEST`로 분리. | 사용자 승인 및 기존 프로젝트·Project K 감사 |
| 2026-08-11 | 독립 검토 뒤 TC namespace, 20:9 safe frame, 물리 비결정성, 재도전 snapshot, P2W 단위 동등성, 타임어택, 분석 시간창, MCP/export·Cloud 경계를 보정. | HTML·시장·플러그인/스킬 읽기 전용 리뷰와 Godot 4.7 로컬 공식 문서 |
