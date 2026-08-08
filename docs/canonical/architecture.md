# 아키텍처

`scripts/core`는 `RefCounted` 규칙 코드다. Node, UI, AdMob, Billing, Supabase를 참조하지 않는다.

```text
JSON data -> GameCatalog -> RunSimulator/RunEngine -> RunState -> headless report
```

- `GameCatalog`: JSON 로딩과 참조 검증
- `ChallengeRules`: 도전 3종의 직접 판정
- `RunState`: 버전이 있는 저장 스냅샷
- `RunEngine`: 한 층의 성공·실패·콤보·스토리·체크포인트 처리
- `RunSimulator`: 고정 시드 런과 대량 집계

화면은 이후 core 결과를 표시하고 입력을 전달하는 얇은 계층으로 추가한다. 한 구현만 있는 인터페이스나 공용화를 위한 선행 추상화는 만들지 않는다.
