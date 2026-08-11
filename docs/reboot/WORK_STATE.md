# Quirky Tower Reboot Work State

갱신일: **2026-08-11**
현재 단계: **Gate A implementation candidate / Human gate blocked**
브랜치: **`codex/reboot-vertical-slice`**
시각 증거: **runtime `c66e2e0` / evidence `6b9818b` / runner cleanup `e85ecac`**

## 현재

- 오리 리더·거위·비둘기, 한 구역, Approach → Brawl → Chain Raid → 세로 3택을 같은 `FlockRunState`로 연결한 Gate A greybox 구현 후보가 있다.
- 고정 사선 직교 카메라, 실제 collider, authored destruction, 단일 pointer 취소, 1회 보상, 재시작 정리를 Godot 4.7 headless/runtime 테스트로 검사했다.
- macOS Metal Forward Mobile / Apple M2에서 코드 상태 14개를 1080×2400 PNG로 캡처했다. 해시·seed·locale·viewport 경계는 [`../../qa_output/reboot_gate_a/after/README.md`](../../qa_output/reboot_gate_a/after/README.md)에 있다.
- 독립 증거 리뷰에서 Critical/Important 0, 화면 P1 0으로 Gate A 시각 증거 수용 가능 판정을 받았다.
- 레거시 Timing Ring 비포 2장은 같은 1080×2400이지만 새 코어와 의미상 동등하지 않아 `not directly comparable`이다.
- 최종 유지 6개 테스트, `check_project.sh`, cleanup self-test가 PASS했고 새 agent-owned Godot/MCP PID·listener는 0이다. 시작 전부터 있던 Quirky Ball PID `4266`은 보존했다.
- GA-01·03·04·08·09·11은 증거 범위가 부족해 `Partial`, GA-12는 외부 5인이 없어 `Blocked`다.
- 최종 아트 패밀리는 `quirky_tower_urban_broadcast_cel_v1`이다. 최신 Project K 애니·셀 제작 언어와 ZZZ의 상위 도시·그래픽 에너지만 참고하고, 구체 캐릭터·로고·복장·체형·UI·셰이더·샷은 복제하지 않는다.
- 현재 저폴리·픽셀 모델은 Gate A greybox로만 유효하다. 중밀도 cel 3D, 2–3단계 명암, 제한 네온, 오리 Truth Kit은 Gate C 범위다.
- 주 체크아웃의 기존 canonical dirty 변경은 이 브랜치에서 건드리지 않았다.

## 다음 P0

1. GA-03 popup stale-release, GA-04 hazard/dodge, GA-08 different-seed, GA-11 failure restart의 focused 증거를 한 배치로 보완한다.
2. 개발자 외 5명으로 10초 행동 이해, 충돌·붕괴 인과, 3막 구분, 자발 재도전을 관찰한다.
3. Gate A 사람 기준을 통과한 뒤에만 Gate B 5분 런 또는 Gate C 오리 Truth Kit으로 확장한다.

## 미검증

- Gate A 외부 5인 이해도·인과·3막 구분·자발 재도전. 따라서 **Gate A는 미통과**다.
- 실제 스마트폰 손가락 입력, Android/iOS safe area·성능·오디오·햅틱·resume.
- GA-01 동등 비포, GA-03 popup stale-release, GA-04 hazard/dodge, GA-08 different-seed, GA-09 후속 두 막·DE/AR, GA-11 failure restart.
- Gate B의 세 구역·송출실·닭·까마귀·3회 빌드·5분 페이싱.
- Gate C의 `quirky_tower_urban_broadcast_cel_v1` cel 3D·2D·profile·shop·frame 자산, 20:9·흑백 비교, 4스템·SFX 청음.
- Sponsor Ticket, AdMob, Billing, StoreKit, Supabase, 실제 랭킹·국가/소속, 분석 SDK.
