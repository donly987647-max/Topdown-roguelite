# LAST MAGAZINE — GDD Coverage Matrix

> GDD 1.0 구현 누락 방지 추적표. 사용자 최종 피드백 전 필수 범위 전체 구현·런타임 검증이 필요하다.

## Status Rules
- `NOT STARTED`: 구현 없음
- `PARTIAL`: 코드/프로토타입은 있으나 GDD 전체 요구 미충족
- `IMPLEMENTED`: 요구 기능이 코드상 구현됨
- `VALIDATED`: 실제 실행·입력·저장·QA 검증 완료
- 실제 Godot 실행 성공을 확인하지 못한 기능은 `VALIDATED`로 올리지 않는다.

## Global Release Gates
- [ ] Godot 4.7.1 정식 소스 구조 확정 및 실제 실행 검증
- [ ] GDD 1~80 전체 섹션 누락 검토
- [ ] GDD 67.1 콘텐츠 목표량 충족 또는 승인 축소안 문서화
- [ ] GDD 74.1 최소 출시 범위 충족
- [ ] GDD 74.3 축소 금지 품질 항목 통과
- [ ] GDD 72.6 출시 후보 기준 통과
- [ ] GDD 75 QA 계획 통과
- [ ] Windows/Steam 전체 진행 검증
- [ ] Android 설치/저장/입력 검증
- [ ] 위 게이트 후에만 사용자 최종 피드백 요청

## GDD Section Coverage
| # | GDD Section | Status | Current Note |
|---:|---|---|---|
| 1 | 게임 개요 | **NOT STARTED** | 제품 정의 검증 단계 미도달 |
| 2 | 핵심 디자인 목표 | **PARTIAL** | 총기 조립/6×5 가방/방 기반 런 구조는 코드에 존재하나 재미·가독성 검증 전 |
| 3 | 목표 이용자 | **NOT STARTED** | 검증 대상 문서 항목 |
| 4 | 세계관 | **NOT STARTED** | 서사/환경 전달 콘텐츠 미구현 |
| 5 | 전체 게임 구조 | **PARTIAL** | 기본 실행 Scene이 Main Menu→Character Select→Zone1 Run→GR-01→Result 흐름으로 변경. 4구역/허브/메타 미완 |
| 6 | 게임 루프 | **PARTIAL** | 실제 방 로딩, 위협도 wave, 3택 보상, 경로 선택, 시설, 보스 성공/실패 결과, room-entry checkpoint 기반 존재 |
| 7 | 플레이어 조작 | **PARTIAL** | 키보드/마우스·Android 기초. 게임패드/키 재지정 미완 |
| 8 | 플레이어 이동 | **PARTIAL** | 기본 260 px/s, 가감속을 GDD 0.08/0.06초 목표에 맞춘 기반. 무기별 이동 페널티 등 미완 |
| 9 | 회피 구르기 | **PARTIAL** | 대시/i-frame 기반 존재; 정밀 회피/낙하 방지/QA 미완 |
| 10 | 생명력과 방어 | **PARTIAL** | HP/피격/사망/임시 보호막, 사망→런 실패 연결. 방어판 정식 시스템/UI 미완 |
| 11 | 조준과 사격 | **PARTIAL** | projectile payload + swept collision 기반. 첫 사용자 플레이에서 일반 적이 기본 물리 레이어에 남아 탄환이 관통하는 치명 결함 발견→EnemyBody 레이어 수정 및 회귀 테스트 추가. 실제 재플레이 QA 남음 |
| 12 | 재장전 시스템 | **PARTIAL** | 탄창/완벽 재장전/취소/상태형 탄창 유지. 사용자 결정으로 총 예비탄은 무한화하여 탄약 고갈 soft-lock 제거; 기존 GDD 탄약 경제는 추후 재정의 필요 |
| 13 | 과열 시스템 | **PARTIAL** | heat/cool/overheat와 Rotary/Beam 연동. 밸런스/QA 미완 |
| 14 | 무기 시스템 | **PARTIAL** | WeaponBuild/EffectResolver + starter frame-only 런타임. 완성 조립 UI/전체 저장/QA 미완 |
| 15 | 무기 프레임 | **PARTIAL** | 12종 데이터와 발사 런타임 기반. 영구 드론/레일 감속/런처 자폭 등 fidelity 미완 |
| 16 | 총열 부품 | **PARTIAL** | 12종 핵심 projectile runtime 기반. 자원 규칙/밸런스/QA 미완 |
| 17 | 탄창 부품 | **PARTIAL** | 12종 stat/projectile/MagazineRuntime 기반. 일부 세부 규칙/UI/QA 미완 |
| 18 | 코어 부품 | **PARTIAL** | 12종 기반 + Devour elite room persistence. Impact 벽 보너스/전도 지형 등 미완 |
| 19 | 상태 이상 | **PARTIAL** | 7종 및 일부 조합 반응. 보스/환경 변환/QA 미완 |
| 20 | 장비 격자 시스템 | **PARTIAL** | 6×5 배치/회전/단자/전력/직렬화/자동배치. 실제 인벤토리 UI·전투 잠금 미완 |
| 21 | 패시브 모듈 | **PARTIAL** | 정의/런타임 집계/트리거 기반. 60종 실효과/콘텐츠/UI 미완 |
| 22 | 액티브 장비 | **PARTIAL** | 쿨다운/충전/활성 payload 기반. 20종 실제 효과/입력/UI 미완 |
| 23 | 등급과 희귀도 | **PARTIAL** | 보상 rarity weighting/표시/경로 보너스 기반. 전체 드랍표·아트 규칙 미완 |
| 24 | 시너지 시스템 | **PARTIAL** | 방향성 네트워크 + explicit/tag-tier 실행 기반. 50종 실전 시너지 미완 |
| 25 | 캐릭터 | **PARTIAL** | Mara/Kane/Nova/Rex + 잠금 Shell-07 카탈로그, 선택 UI, HP/속도/시작 고철/시작 프레임 실제 적용. 개별 패시브·액티브/해금 로직 미완 |
| 26 | 방과 맵 생성 | **PARTIAL** | 수작업 템플릿, 그래프 조합, 32px 타일, 실제 Zone1 `.tscn` 11종, 맵 UI/분기/반복 억제. 120개/비밀길 미완 |
| 27 | 방 종류 | **PARTIAL** | combat/elite/shop/crafting/medical/event/rest/start/boss 기반과 출구 lifecycle 존재. 비밀방/세부 상호작용 미완 |
| 28 | 전투 위협도 | **PARTIAL** | threat cost/tag→1~3 wave→PackedScene spawn. overspend 버그 수정. 전체 적 비용표/편대/밸런스 미완 |
| 29 | 적 AI 공통 규칙 | **PARTIAL** | Chaser/Ranged 베이스와 Zone1 profile override. 공통 인식/벽 끼임/패턴 표준 미완 |
| 30 | 제1구역: 폐기 조립라인 | **PARTIAL** | 실제 `.tscn` 11종, 7 적 프로필, 장애물/위험/스폰 데이터, 시설/엘리트/보스방. P4 8적·정식 아트/연출/20분 완성도 미완 |
| 31 | 제1구역 보스: 폐기물 압축기 GR-01 | **PARTIAL** | 전용 GR01Boss/arena. 60%/25% 3페이즈, 압축벽/파편/컨베이어/낙하블록/추적톱날/잡병/안전구역/코어 노출 기반. 정식 VFX/오디오/보상/밸런스 QA 미완 |
| 32 | 제2구역: 생화학 처리시설 | **NOT STARTED** | GDD 기준 미구현 |
| 33 | 제2구역 보스: 누출된 실험체 EVE-09 | **NOT STARTED** | GDD 기준 미구현 |
| 34 | 제3구역: 중앙 탄약저장고 | **NOT STARTED** | GDD 기준 미구현 |
| 35 | 제3구역 보스: 자동포대 열차 ATLAS | **NOT STARTED** | GDD 기준 미구현 |
| 36 | 제4구역: 지휘 제어망 | **NOT STARTED** | GDD 기준 미구현 |
| 37 | 최종 보스: MOTHERLINE | **NOT STARTED** | GDD 기준 미구현 |
| 38 | 비밀 구역: 기억 보관소 | **NOT STARTED** | GDD 기준 미구현 |
| 39 | 보상 시스템 | **PARTIAL** | build-related/random/new-direction 3택 + 실제 RewardChoicePanel + 지급→route unlock. 최종 inventory/equipment 적용 미완 |
| 40 | 상자 | **NOT STARTED** | GDD 기준 미구현 |
| 41 | 런 내부 경제 | **PARTIAL** | RunWallet + Shop/Crafting/Medical + 시설 coordinator. 시설 Control UI/최종 가격·수입 밸런스 미완 |
| 42 | 저주 시스템 | **NOT STARTED** | GDD 기준 미구현 |
| 43 | 영구 성장 | **NOT STARTED** | GDD 기준 미구현 |
| 44 | 허브 | **NOT STARTED** | GDD 기준 미구현 |
| 45 | 난도 시스템 | **PARTIAL** | threat multiplier/route risk 기반. 정식 단계·보상·적 변화 규칙 미완 |
| 46 | 튜토리얼 | **NOT STARTED** | GDD 기준 미구현 |
| 47 | UI 구조 | **PARTIAL** | 전투 HUD와 full route map을 분리. 전체 경로 노드는 전투 중 숨기고 전투/보상 해결 후 경로 선택 시만 표시. GDD 47.1 전투용 미니맵은 별도 구현 필요 |
| 48 | 인벤토리 UI | **NOT STARTED** | GDD 기준 미구현 |
| 49 | 지도 UI | **PARTIAL** | graph/visited/cleared/current/safe-risk route 클릭 UI 존재. 첫 플레이 피드백 반영으로 full graph는 post-combat route selection 전용; 전투 overlay 금지. 최종 아트/미니맵 미완 |
| 50 | 접근성 | **NOT STARTED** | GDD 기준 미구현 |
| 51 | 그래픽 방향 | **PARTIAL** | 기능용 polygon/floor/room prototype 존재; 정식 픽셀아트/배경/연출은 미완 |
| 52 | 카메라 | **PARTIAL** | Player Camera2D + 방 진입 위치/32px camera limits 실제 적용. shake/보스 연출 미완 |
| 53 | 이펙트 | **PARTIAL** | 기초 muzzle/hit 및 GR-01 텔레그래프 기반. 정식 VFX 미완 |
| 54 | 사운드 | **NOT STARTED** | GDD 기준 미구현 |
| 55 | 대사와 텍스트 | **PARTIAL** | 캐릭터/메뉴/결과 기초 텍스트 존재. 서사/대사 콘텐츠 미완 |
| 56 | 로컬라이징 | **NOT STARTED** | GDD 기준 미구현 |
| 57 | 저장 시스템 | **PARTIAL** | RunSaveService v3: graph/run/character/wallet/backpack/template/reward + HP/shield/frame/ammo/reserve/heat atomic checkpoint 저장·복원. 완성 조립 저장/마이그레이션/손상복구/Steam Cloud 미완 |
| 58 | 통계와 도감 | **NOT STARTED** | GDD 기준 미구현 |
| 59 | 업적 | **NOT STARTED** | GDD 기준 미구현 |
| 60 | 일일 시드와 도전 | **PARTIAL** | seed 기반 RunGraph 지원. daily 규칙/리더보드 미완 |
| 61 | 밸런스 기준 | **PARTIAL** | threat/reward/path/GR-01 조절점 존재. 실제 반복 플레이 데이터 미검증 |
| 62 | 무작위성 원칙 | **PARTIAL** | seeded route + weighted/build-aware rewards + template reuse suppression. RNG stream 완전 분리 미완 |
| 63 | 기술 구조 | **PARTIAL** | data/runtime/scene/run/save/frontend 계층 + Godot 4.7.1 CI. baseline run #154에서 86 GDScript 전수 parse/boot/기존 smoke 성공 관측; hands-on 회귀 gate 추가 |
| 64 | 성능 목표 | **NOT STARTED** | 프로파일링/목표 검증 미실시 |
| 65 | 화면 비율과 디스플레이 | **PARTIAL** | 첫 사용자 플레이 피드백으로 1280×720 강제 창 제거, desktop fullscreen + canvas `expand` 적용. 다양한 모니터 비율/UI scale 수동 QA 남음 |
| 66 | Steam 출시 기능 | **NOT STARTED** | GDD 기준 미구현 |
| 67 | 콘텐츠 목표량 | **PARTIAL** | 12 frame/barrel/mag/core 데이터, Zone1 11 rooms/7 profiles 등 일부 카탈로그 존재. 출시 목표량 미충족 |
| 68 | 게임 모드 | **NOT STARTED** | GDD 기준 미구현 |
| 69 | 엔딩 | **NOT STARTED** | GDD 기준 미구현 |
| 70 | 리플레이 가치 | **PARTIAL** | safe/risky routes, seed, character choice, build-aware rewards 기반. 전체 콘텐츠/엔딩/도전 다양성 미완 |
| 71 | 출시 가격과 판매 방향 | **NOT STARTED** | 제작/판매 문서 항목 |
| 72 | 개발 단계 | **PARTIAL** | P2 one-zone 구조는 frontend→run→boss→result까지 코드상 연결. P2 완료 판정에는 실제 Godot 실행·3회 완주·저장 재실행 검증이 남음 |
| 73 | 권장 팀 구성 | **NOT STARTED** | 구현 대상이 아닌 제작 계획 문서 항목 |
| 74 | 최소 출시 범위와 확장 범위 | **PARTIAL** | 필수 시스템 일부 존재하나 4구역/캐릭터 실효과/패드/설정/Steam 등 미충족 |
| 75 | QA 계획 | **PARTIAL** | 86 GDScript 전수 parse + main boot + 기존 smoke에 hands-on blocker regression smoke 추가. baseline run #154 성공 관측; 사용자 실제 재플레이/Windows 전체 런 QA 남음 |
| 76 | 주요 위험 요소 | **PARTIAL** | 시스템 과밀/조합폭발/콘텐츠량/가독성/운 의존 위험은 추적 중. 실제 안정성 검증 전 |
| 77 | 핵심 성공 기준 | **NOT STARTED** | 첫 5분 재미/피격 이해/보스 학습/빌드 재미 플레이 검증 미실시 |
| 78 | 최종 제품 정의 | **NOT STARTED** | 출시 정의 미충족 |
| 79 | 최종 핵심 요약 | **NOT STARTED** | 출시 정의 미충족 |
| 80 | 후속 제작 문서 목록 | **PARTIAL** | PROJECT/GDD_COVERAGE 운영 문서 존재. 나머지 제작 문서 미완 |

## Explicit Content Count Gates
- [ ] 플레이 캐릭터 4명 + 비밀 1명 — 카탈로그는 존재하나 개별 실효과/해금/QA 미완
- [ ] 기본 구역 4개 + 비밀 1개
- [ ] 무기 프레임 12종 — 데이터/런타임 기반은 있으나 전체 QA 전
- [ ] 총열 12종 이상 — 기반은 있으나 전체 QA 전
- [ ] 탄창 12종 이상 — 기반은 있으나 전체 QA 전
- [ ] 코어 12종 이상 — 기반은 있으나 전체 QA 전
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

## Minimum Mandatory Launch Scope — GDD 74.1
- [ ] 캐릭터 3명 이상 실제 완성
- [ ] 기본 구역 4개
- [ ] 최종 보스
- [ ] 무기 프레임 8종 이상 실제 완성
- [ ] 부품 30종 이상 실제 완성
- [ ] 모듈 40종 이상
- [ ] 게임패드
- [ ] 저장 안정성
- [ ] 설정
- [ ] 접근성
- [ ] Steam 기능
- [ ] 기본 엔딩
- [ ] 20시간 이상의 유효 플레이 콘텐츠

## Non-Cuttable Quality Gates — GDD 74.3
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

## Validation State
- Godot 4.7.1 baseline validation run #154 was observed green for exhaustive 86-script parsing, main boot and the pre-existing smoke suite.
- First hands-on playtest exposed defects outside that prior coverage, so no gameplay row is promoted to VALIDATED solely from run #154.
- `first_playtest_regression_smoke.gd` now covers fullscreen, route-map timing, collision-layer contracts and infinite starter reserve ammo; user re-play remains required.

## Update Rule
1. 의미 있는 코드 변경마다 관련 행을 갱신한다.
2. `IMPLEMENTED`는 GDD 요구가 코드상 충족될 때만 사용한다.
3. 실제 실행·입력·저장·QA를 확인한 뒤에만 `VALIDATED`로 올린다.
4. GDD와 구현이 다르면 PROJECT.md Design Decisions에 기록한다.
5. 최종 피드백 요청 전 GDD 원문과 이 매트릭스를 재대조해 누락 0개를 확인한다.
