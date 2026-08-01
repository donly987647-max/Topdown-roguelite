# LAST MAGAZINE — GDD Coverage Matrix

> 이 문서는 GDD 1.0의 구현 누락을 방지하기 위한 추적표다. 사용자에게 최종 피드백을 요청하기 전에 이 문서의 **필수 범위가 전부 구현·런타임 검증 완료**되어야 한다.

## Status Rules
- `NOT STARTED`: 구현 없음
- `PARTIAL`: 일부 코드/프로토타입 존재하지만 GDD 요구 전체를 충족하지 않음
- `IMPLEMENTED`: 요구 기능이 코드상 완전 구현됨
- `VALIDATED`: 실제 실행·입력·저장·QA로 검증 완료
- 코드가 존재해도 실행 검증이 없으면 `VALIDATED`로 올리지 않는다.

## Global Release Gates
- [ ] Godot 4.7.1 기준 정식 소스 구조 확정
- [ ] GDD 1~80 전체 섹션 구현 커버리지 검토 완료
- [ ] 74.1 반드시 포함할 범위 전부 구현
- [ ] 74.3 축소 금지 품질 항목 전부 통과
- [ ] 67.1 출시 콘텐츠 목표량 충족 또는 승인 축소안 문서화
- [ ] 72.6 출시 후보 기준 통과
- [ ] 75 QA 계획 통과
- [ ] Windows/Steam 전체 진행 검증
- [ ] Android 전체 진행/설치/저장/입력 검증
- [ ] 누락 검증 후에만 사용자 최종 피드백 요청

## GDD Section Coverage
| # | GDD Section | Status | Current Note |
|---:|---|---|---|
| 1 | 게임 개요 | **NOT STARTED** | GDD 기준 구현 필요 |
| 2 | 핵심 디자인 목표 | **NOT STARTED** | GDD 기준 구현 필요 |
| 3 | 목표 이용자 | **NOT STARTED** | GDD 기준 구현 필요 |
| 4 | 세계관 | **NOT STARTED** | GDD 기준 구현 필요 |
| 5 | 전체 게임 구조 | **PARTIAL** | RunGraph + RunStateController + RunSceneCoordinator로 Start→실제 방 로딩→클리어→보상→경로 선택→다음 Scene 전환 기반 구현; 구역 진행/허브 복귀/최종 정산 미완 |
| 6 | 게임 루프 | **PARTIAL** | 방 Scene 진입, 전투 wave, 보상 gate, 출구 route binding까지 런 흐름에 연결; 메인 메뉴/캐릭터 선택/결과/메타 반영 미완 |
| 7 | 플레이어 조작 | **PARTIAL** | PC/Android 입력 기반 일부 구현; 게임패드 미구현 |
| 8 | 플레이어 이동 | **PARTIAL** | 이동/가감속 구현, GDD 수치·감각 검증 미완; Rail Lancer 충전 이동감속 미연결 |
| 9 | 회피 구르기 | **PARTIAL** | 대시/i-frame 구현, 정밀 회피/낙하 방지 미완 |
| 10 | 생명력과 방어 | **PARTIAL** | HP/피격/사망과 임시 보호막 런타임 구현; 정식 방어판/UI/전체 검증 미완 |
| 11 | 조준과 사격 | **PARTIAL** | payload 탄환, 관통·유도·치명타·폭발·연쇄, swept ray/법선 도탄 구현; 피드백·충돌 QA 미완 |
| 12 | 재장전 시스템 | **PARTIAL** | 예비 탄약, 자동/완벽 재장전, 대시 취소 및 상태형 탄창 런타임 추가; Reactive Magazine once-per-room 상태를 room lifecycle 진입 시 리셋하도록 연결; UI/QA 미완 |
| 13 | 과열 시스템 | **PARTIAL** | 열/냉각/과열 잠금과 Rotary/Beam 연동; 밸런스·실행 검증 미완 |
| 14 | 무기 시스템 | **PARTIAL** | WeaponBuild/EffectResolver/프레임·총열·탄창·코어 실행 계층 구현; UI/저장/전체 QA 미완 |
| 15 | 무기 프레임 | **PARTIAL** | 12종 데이터와 고유 발사 런타임 기반 구현; 영구 드론/레일 감속/런처 자폭 등 fidelity 및 QA 미완 |
| 16 | 총열 부품 | **PARTIAL** | 12종 핵심 projectile runtime 구현; 일부 자원 규칙·분열 안정성·밸런스/QA 미완 |
| 17 | 탄창 부품 | **PARTIAL** | 12종 핵심 stat/projectile/MagazineRuntime 경로 구현; Reactive per-room reset 연결 완료, 무기교체 보너스·UI·QA 미완 |
| 18 | 코어 부품 | **PARTIAL** | 12종 실행 경로 기반 구현; 충격 벽보너스, Devour 엘리트 지속, 지형 전도 등 fidelity/QA 미완 |
| 19 | 상태 이상 | **PARTIAL** | 7종 축적·틱·동결·연쇄·피해증폭 및 일부 조합반응 구현; 보스/지형/QA 미완 |
| 20 | 장비 격자 시스템 | **PARTIAL** | 6×5 배치/회전/단자 + BackpackState 인스턴스 ID/자동배치/직렬화·복원 구현; UI·드래그·전투 잠금 미완 |
| 21 | 패시브 모듈 | **PARTIAL** | PassiveModuleDefinition + PassiveModuleRuntime 추가; 60종 카탈로그/개별 효과/UI/QA 미완 |
| 22 | 액티브 장비 | **PARTIAL** | ActiveEquipmentDefinition + Runtime 추가; 20종 카탈로그/입력/UI/개별 효과/QA 미완 |
| 23 | 등급과 희귀도 | **PARTIAL** | RewardOffer/RewardSelector rarity weighting + 안전/위험 경로 reward metadata 기반 추가; 전체 드랍표/표시 미완 |
| 24 | 시너지 시스템 | **PARTIAL** | 방향성 네트워크 + BackpackSynergyExecutor explicit/tag tier 효과 기반 구현; 정식 50종/실전 적용/UI 미완 |
| 25 | 캐릭터 | **NOT STARTED** | GDD 기준 구현 필요 |
| 26 | 방과 맵 생성 | **PARTIAL** | 수작업 RoomTemplateDefinition + Registry + scene_path/group contracts + RoomSceneRuntime 실제 Scene 로딩 기반 구현. 그래프 안전/위험 분기와 템플릿 선택까지 연결; 120개 콘텐츠/구역별 규칙/비밀길 완성 미완 |
| 27 | 방 종류 | **PARTIAL** | combat/elite/shop/event/rest/start/boss 그래프 유형 + 1~3 wave lifecycle + reusable RoomExitGate 추가; 제작실/의료실/비밀방 등 전체 세부 행동·콘텐츠 미완 |
| 28 | 전투 위협도 | **PARTIAL** | ThreatBudgetPlanner + EnemySpawnRegistry + RoomSceneRuntime으로 위협 예산→wave entries→PackedScene 적 생성 경로 연결; 실제 32종 적 비용표/스폰 타이밍·편대/밸런스 QA 미완 |
| 29 | 적 AI 공통 규칙 | **PARTIAL** | Chaser/Ranged AI와 상태 영향 일부 구현; 공통 인식·벽 끼임·예고 규칙 미완 |
| 30 | 제1구역: 폐기 조립라인 | **NOT STARTED** | GDD 기준 구현 필요 |
| 31 | 제1구역 보스: 폐기물 압축기 GR-01 | **NOT STARTED** | GDD 기준 구현 필요 |
| 32 | 제2구역: 생화학 처리시설 | **NOT STARTED** | GDD 기준 구현 필요 |
| 33 | 제2구역 보스: 누출된 실험체 EVE-09 | **NOT STARTED** | GDD 기준 구현 필요 |
| 34 | 제3구역: 중앙 탄약저장고 | **NOT STARTED** | GDD 기준 구현 필요 |
| 35 | 제3구역 보스: 자동포대 열차 ATLAS | **NOT STARTED** | GDD 기준 구현 필요 |
| 36 | 제4구역: 지휘 제어망 | **NOT STARTED** | GDD 기준 구현 필요 |
| 37 | 최종 보스: MOTHERLINE | **NOT STARTED** | GDD 기준 구현 필요 |
| 38 | 비밀 구역: 기억 보관소 | **NOT STARTED** | GDD 기준 구현 필요 |
| 39 | 보상 시스템 | **PARTIAL** | build-related/random/new-direction 3택 + 중복 억제/pity + RewardGrantResolver 구현. RunSceneCoordinator가 combat clear 후 출구를 잠근 채 reward panel event를 발생시키고 지급 후 route를 개방; 실제 Control UI 미완 |
| 40 | 상자 | **NOT STARTED** | GDD 기준 구현 필요 |
| 41 | 런 내부 경제 | **PARTIAL** | RewardGrantResolver scrap 지급 contract 기반; 정식 Wallet/가격/상점/평균 수입 밸런스 미완 |
| 42 | 저주 시스템 | **NOT STARTED** | GDD 기준 구현 필요 |
| 43 | 영구 성장 | **NOT STARTED** | GDD 기준 구현 필요 |
| 44 | 허브 | **NOT STARTED** | GDD 기준 구현 필요 |
| 45 | 난도 시스템 | **PARTIAL** | ThreatBudgetPlanner difficulty multiplier와 경로 위험 metadata 기반; 정식 난도 단계/보상/적 변화 규칙 미완 |
| 46 | 튜토리얼 | **NOT STARTED** | GDD 기준 구현 필요 |
| 47 | UI 구조 | **PARTIAL** | `RewardChoiceViewModel`/`RunMapViewModel`로 보상·지도 표시용 데이터 계약 추가; 실제 Control scene/controller navigation/production HUD 미완 |
| 48 | 인벤토리 UI | **NOT STARTED** | GDD 기준 구현 필요 |
| 49 | 지도 UI | **PARTIAL** | RunMapViewModel이 graph/visited/cleared/current/route class 데이터를 UI-ready node/edge 구조로 변환; 실제 지도 화면 및 선택 입력 미완 |
| 50 | 접근성 | **NOT STARTED** | GDD 기준 구현 필요 |
| 51 | 그래픽 방향 | **NOT STARTED** | GDD 기준 구현 필요 |
| 52 | 카메라 | **PARTIAL** | RoomTemplateDefinition camera_bounds + camera anchor group 계약 존재; 실제 Camera2D 제한 적용/흔들림/보스 카메라 미완 |
| 53 | 이펙트 | **PARTIAL** | 기초 플래시 훅 일부; 전체 VFX 미완 |
| 54 | 사운드 | **NOT STARTED** | GDD 기준 구현 필요 |
| 55 | 대사와 텍스트 | **NOT STARTED** | GDD 기준 구현 필요 |
| 56 | 로컬라이징 | **NOT STARTED** | GDD 기준 구현 필요 |
| 57 | 저장 시스템 | **PARTIAL** | Backpack/Reward/RunGraph/RunState 직렬화 기반 존재; 실제 Scene/template binding 복원과 디스크 SaveGame/version migration 미완 |
| 58 | 통계와 도감 | **NOT STARTED** | GDD 기준 구현 필요 |
| 59 | 업적 | **NOT STARTED** | GDD 기준 구현 필요 |
| 60 | 일일 시드와 도전 | **PARTIAL** | RunGraphGenerator seed 입력 지원; 실제 daily seed/리더보드/도전 모드 미완 |
| 61 | 밸런스 기준 | **PARTIAL** | 위협 예산/경로 위험/보상 가중치 조절점 추가; 전체 수치표 및 플레이 QA 미완 |
| 62 | 무작위성 원칙 | **PARTIAL** | seeded graph + weighted/build-aware reward + limited template reuse 구조 추가; RNG stream 분리/완전 재현성 미완 |
| 63 | 기술 구조 | **PARTIAL** | RunSceneCoordinator/RoomSceneRuntime/EnemySpawnRegistry/RoomExitGate 추가로 데이터→Scene→Encounter→Reward→Route 통합 계층 형성. smoke scripts 존재하나 실제 headless 실행·회귀 CI 미완 |
| 64 | 성능 목표 | **NOT STARTED** | GDD 기준 구현 필요 |
| 65 | 화면 비율과 디스플레이 | **PARTIAL** | 1920x1080 기반만 존재, 비율/모드/UI 배율 미검증 |
| 66 | Steam 출시 기능 | **NOT STARTED** | GDD 기준 구현 필요 |
| 67 | 콘텐츠 목표량 | **NOT STARTED** | 목표량 데이터/실전 콘텐츠 미충족 |
| 68 | 게임 모드 | **NOT STARTED** | GDD 기준 구현 필요 |
| 69 | 엔딩 | **NOT STARTED** | GDD 기준 구현 필요 |
| 70 | 리플레이 가치 | **PARTIAL** | 안전/위험 분기, seeded route, build-aware 3택, 템플릿 반복 억제 기반 추가; 전체 캐릭터/콘텐츠/도전/엔딩 다양성 미완 |
| 71 | 출시 가격과 판매 방향 | **NOT STARTED** | GDD 기준 구현 필요 |
| 72 | 개발 단계 | **PARTIAL** | P2 한 구역 런 루프가 상태/보상/방 lifecycle을 넘어 실제 room scene/spawn/exit gate 통합까지 진행. UI/콘텐츠/보스 정산/중간저장 미완 |
| 73 | 권장 팀 구성 | **NOT STARTED** | 구현 대상이 아닌 제작 계획 문서 항목 |
| 74 | 최소 출시 범위와 확장 범위 | **PARTIAL** | 일부 필수 시스템 구조만 구현; 최소 출시 범위 미충족 |
| 75 | QA 계획 | **PARTIAL** | `gdd_runtime_smoke`, `run_system_smoke`, `run_lifecycle_smoke`, `room_scene_smoke` 추가; 실제 Godot 실행/자동 CI/플레이 QA 미완 |
| 76 | 주요 위험 요소 | **PARTIAL** | Scene integration까지 코드 커버리지는 증가했으나 Godot 실행 검증 부재와 콘텐츠/UI/저장/플랫폼 위험 지속 |
| 77 | 핵심 성공 기준 | **NOT STARTED** | GDD 성공 기준 검증 미실시 |
| 78 | 최종 제품 정의 | **NOT STARTED** | 출시 정의 미충족 |
| 79 | 최종 핵심 요약 | **NOT STARTED** | 출시 정의 미충족 |
| 80 | 후속 제작 문서 목록 | **PARTIAL** | PROJECT.md/GDD_COVERAGE.md가 운영 문서 역할 중; 나머지 제작 문서 미완 |

## Explicit Content Count Gates
- [ ] 플레이 캐릭터 4명 + 비밀 1명
- [ ] 기본 구역 4개 + 비밀 1개
- [ ] 무기 프레임 12종
- [ ] 총열 12종 이상
- [ ] 탄창 12종 이상
- [ ] 코어 12종 이상
- [ ] 패시브 모듈 60종
- [ ] 액티브 장비 20종
- [ ] 일반 적 32종 이상
- [ ] 엘리트 변형 12종 이상
- [ ] 중간 보스 4종
- [ ] 주요 보스 5종 이상
- [ ] 방 템플릿 120개 이상
- [ ] 이벤트 35개 이상
- [ ] 시너지 50개 이상
- [ ] 업적 40~50개
- [ ] 엔딩 3종 이상

> 카탈로그 수량 데이터가 존재하더라도 실제 런 등장·효과·UI·저장·입력·QA 조건을 만족하기 전에는 콘텐츠 수량 게이트를 체크하지 않는다.

## Minimum Mandatory Launch Scope (GDD 74.1)
- [ ] 캐릭터 3명 이상
- [ ] 기본 구역 4개
- [ ] 최종 보스
- [ ] 무기 프레임 8종 이상
- [ ] 부품 30종 이상
- [ ] 모듈 40종 이상
- [ ] 게임패드
- [ ] 저장
- [ ] 설정
- [ ] 접근성
- [ ] Steam 기능
- [ ] 기본 엔딩
- [ ] 20시간 이상의 유효 플레이 콘텐츠

## Non-Cuttable Quality Gates (GDD 74.3)
- [ ] 조작감
- [ ] 피격 판정
- [ ] 회피 판정
- [ ] 저장 안정성
- [ ] 프레임 안정성
- [ ] 전투 가독성
- [ ] 보스 품질
- [ ] 기본 UI
- [ ] 게임패드 지원
- [ ] 튜토리얼
- [ ] 사운드 피드백

## Current Conclusion
현재 코드는 GDD 전체 구현판이 아니다. 무기/가방/보상/분기형 런 구조 위에 실제 Godot room scene loading, threat-wave enemy instancing, reward-gated exit flow와 map/reward view-model 계약까지 확장됐지만 Godot 실행 검증과 실제 콘텐츠/UI/저장/플랫폼 통합이 남아 있다.

## Update Rule
1. 의미 있는 코드 변경마다 해당 GDD 섹션 상태를 갱신한다.
2. `IMPLEMENTED` 전환 시 관련 파일/테스트를 Note에 기록한다.
3. 실제 실행 검증이 끝나야 `VALIDATED`로 올린다.
4. GDD와 구현이 다르면 PROJECT.md의 Design Decisions에 변경 사유와 사용자 승인 여부를 기록한다.
5. 최종 피드백 요청 전 GDD 원문과 이 매트릭스를 다시 대조해 누락 항목 0개를 확인한다.
