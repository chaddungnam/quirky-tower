# 디자인 정책

UI는 다음 세 층으로만 공통화한다.

1. `AppTheme.tres`: 폰트와 Godot 컨트롤 기본 스타일
2. `DesignTokens`: 색 역할, 간격, 반경, 글자 크기, 애니메이션 시간
3. 공통 컴포넌트: 버튼, 카드, 팝업, 탭, 칩, 랭킹 행

개별 화면에 색상, 글자 크기, 모서리 값을 직접 넣지 않는다. Quirky Ball 코드는 실제로 두 게임에서 재사용되는 부분만 작은 단위로 옮긴다.

현재 최소 플레이 UI는 `AppTheme.tres`, `DesignTokens`, `RunHud`, `GameOverlay`를 사용한다. 도전별 도형도 Theme 색 역할을 조회하며 개별 hex를 갖지 않는다. 최종 생산 UI와 아트는 아직 확정하지 않았다.
