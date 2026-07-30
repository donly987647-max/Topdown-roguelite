# Execution Order and Milestone Gates

이 문서는 GDD §72의 개발 단계를 실제 선행관계로 고정한다. 다음 단계의 대량 콘텐츠 제작은 이전 게이트 승인 전 시작하지 않는다.

## Gate sequence

| Gate | Required evidence | Blocks |
|---|---|---|
| P0 Foundation | `P0-ENG-001~004`, `P0-QA-001`; 프로젝트/CI/데이터 계약/DoD | P1 gameplay work |
| P1 Pre-production | `P1-GATE-001`; 첫 5분 전투, 이동·회피·피격 원인 검증 | P2 system breadth |
| P2 Core Prototype | `P2-GATE-001`; 10~15분 런, 3프레임·12부품·6×5 가방 검증 | P3 production art/content |
| P3 Vertical Slice | `P3-GATE-001`; 제1구역 20분 판매 영상 품질 | P4 full production |
| P4 Alpha | `P4-GATE-001`; 4구역·기본 엔딩·주요 시스템·60% 콘텐츠 | P5 content lock |
| P5 Beta | `P5-GATE-001`; 콘텐츠 100%, 접근성·다국어·최적화·외부 테스트 | P6 release freeze |
| P6 Release Candidate | `P6-GATE-001`; 차단 버그 0, 저장/성능/입력/Steam 인증 | 1.0 release |

## Immediate next work after backlog approval

다음 구현 배치는 P1 사전 제작이며 아래 순서를 바꾸지 않는다.

1. `P1-INPUT-001` 입력 계층
2. `P1-MOVE-001` 이동
3. `P1-AIM-001` 조준
4. `P1-DASH-001~003` 회피
5. `P1-COMBAT-001~002` 생존·피격
6. `P1-WEAPON-001`, `P1-PROJ-001~002` 기본 총기·탄환
7. `P1-ENEMY-001`, `P1-ROOM-001` 적 1종·방 1개
8. 카메라·피드백·임시 사운드
9. 자동 테스트
10. `P1-GATE-001` 플레이 감각 검수

## Scope control

- P1에서 인벤토리, 상점, 전체 부품, 제1구역 아트 제작을 시작하지 않는다.
- P2 게이트 전에는 대량 콘텐츠 수량을 채우지 않는다.
- P3 게이트 전에는 나머지 구역의 정식 아트 제작을 시작하지 않는다.
- 출시 후보 전에는 `final`, `complete`, `1.0` 표현을 사용하지 않는다.