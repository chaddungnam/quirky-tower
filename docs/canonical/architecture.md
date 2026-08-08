# 아키텍처

`scripts/core`는 `RefCounted` 규칙 코드다. Node, UI, AdMob, Billing, Supabase를 참조하지 않는다.

```text
JSON data -> GameCatalog -> RunSimulator/RunEngine -> RunState -> headless report
TowerStage3D -> TowerTrial scene -> RunController -> RunEngine -> RunState -> HUD/GameOverlay
```

- `GameCatalog`: JSON 로딩과 참조 검증
- `ChallengeRules`: 도전 3종의 직접 판정
- `RunState`: 버전이 있는 저장 스냅샷
- `RunEngine`: 한 층의 성공·실패·콤보·스토리·체크포인트 처리
- `RunSimulator`: 고정 시드 런과 대량 집계
- `RunController`: 통합 층 도전, Quirk·스토리·종료 화면 흐름
- `TowerStage3D`: 고정 카메라 무대, 픽셀 진행자, 저폴리 장애물, 실제 3D 충돌. 점수와 런 상태는 알지 못한다.

## 화면 폴더

- `scenes/app`: 실행 진입점
- `scenes/game`: 런 화면과 독립된 도전 씬
- `scenes/game/world`: 인게임 3D 무대와 충돌 구성
- `scenes/ui/components`: 공통 HUD와 오버레이
- `scripts/game`: 화면 흐름과 사용자 입력
- `scripts/ui`, `ui/themes`: 공통 디자인 토큰과 테마

화면은 core 결과를 표시하고 입력값만 전달한다. 한 구현만 있는 인터페이스나 공용화를 위한 선행 추상화는 만들지 않는다.
