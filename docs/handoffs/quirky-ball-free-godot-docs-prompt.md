# Quirky Ball 동일 도구 적용 프롬프트

아래 내용을 Quirky Ball 작업에 그대로 전달한다.

```text
/Users/junheechoi/projects/houseduck/quirky-ball 에서 작업해줘.

목표는 Quirky Tower와 같은 무료 Godot 문서/MCP 작업 환경을 Quirky Ball에도 안전하게 적용하는 것이다.

1. 먼저 git status와 기존 addon/MCP 구성을 읽기 전용으로 조사하고, 사용자와 다른 작업자의 변경을 보존해라.
2. Context7은 사용하거나 다시 등록하지 마라. 회원가입, API 키, 유료 서비스도 추가하지 마라.
3. godot-mcp가 /Users/junheechoi/.bun/bin/godot-mcp -> /Users/junheechoi/.local/bin/godot-mcp 로 연결된 공식 upstream 0.7.2인지 확인해라. 기대 SHA-256은 7b9b3b5efd34adcdb5962fbaf16ad627aa37c78d25495e81fff9bbee26cecdd3 이다.
4. Quirky Ball에 있는 제3자 개조 Godot MCP의 정확한 파일 범위를 먼저 파악한 뒤, MCP 파일만 공식 Godot Asset Library/upstream 0.7.2 addon으로 교체해라. 다른 addon과 게임 코드는 건드리지 마라. 공식 addon ZIP 기대 SHA-256은 5e7321d1848e6a8dc2ca18abfd23884510026be8f2d5cae547c49d3f84f856c5 이다.
5. /Users/junheechoi/.codex/skills/godot-local-docs/SKILL.md 와 Godot 4.7 로컬 문서 캐시를 그대로 사용해라. /Users/junheechoi/.codex/skills/godot-local-docs/scripts/self_test.sh 를 실행해 PASS를 확인해라. 별도 문서 서비스나 중복 캐시는 만들지 마라.
6. 공식 MCP addon은 개발 도구로만 활성화하고, 출시 export에는 포함되지 않도록 기존 export 설정을 확인해라.
7. Godot 4.7에서 프로젝트 파싱과 기존 Quirky Ball QA를 실행해라. 에디터는 시작 전 godot-mcp status를 확인하고 한 개만 실행해라. BlueStacks, APK 설치, 실제 기기 테스트는 별도 승인 없이 하지 마라.
8. 현재 문서에는 바뀐 도구 계약과 미검증 항목만 짧게 기록해라. 관련 변경만 커밋하고 origin/main에 바로 푸시해라. git 정리는 묻지 마라.

마지막 보고는 무엇을 바꿨는지, 어떤 검증이 PASS인지, 실제 기기에서 무엇을 아직 확인하지 못했는지, 커밋 SHA 순서로 짧게 써라.
```
