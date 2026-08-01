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
- [ ] 67.1 출시 콘텐츠 목표량 충족 또는 사용자가 승인한 공식 축소안 문서화
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
| 5 | 전체 게임 구조 | **NOT STARTED** | GDD 기준 구현 필요 |
| 6 | 게임 루프 | **NOT STARTED** | GDD 기준 구현 필요 |
| 7 | 플레이어 조작 | **PARTIAL** | PC/Android 입력 기반 일부 구현; 게임패드 미구현 |
| 8 | 플레이어 이동 | **PARTIAL** | 이동/가감속 구현, GDD 수치·감각 검증 미완; Rail Lancer 충전 이동감속 미연결 |
| 9 | 회피 구르기 | **PARTIAL** | 대시/i-frame 구현, 정밀 회피/낙하 방지 미완 |
| 10 | 생명력과 방어 | **PARTIAL** | HP/피격/사망과 임시 보호막 런타임 구현; 정식 방어판/UI/전체 검증 미완 |
| 11 | 조준과 사격 | **PARTIAL** | 조준/사격, payload 탄환, 관통·유도·치명타·폭발·연쇄, swept ray 연속충돌과 표면법선 도탄 구현; 명중 피드백·충돌마스크·실행 QA 미완 |
| 12 | 재장전 시스템 | **PARTIAL** | 예비 탄약, 자동 재장전, 완벽 재장전, 대시 취소 + 비상/자기/반응/도박/이중 탄창용 재장전 런타임 추가; 실제 방 단위 사용횟수·UI·Godot 검증 미완 |
| 13 | 과열 시스템 | **PARTIAL** | 0~100 열/냉각/과열 잠금과 Rotary/Beam 연동; 고열 특수 빌드·밸런스·실행 검증 미완 |
| 14 | 무기 시스템 | **PARTIAL** | WeaponBuild 조립, 호환, 전력·중량 과부하, 실전 스탯 반영, 범용 effect payload, 프레임/총열/탄창/코어 실행 계층 확장; UI/저장/밸런스/QA 미완 |
| 15 | 무기 프레임 | **PARTIAL** | 12종 데이터 + 서비스/버스트/SMG/샷건/레일/로터리/런처/아크/빔/톱날/드론기초/해머 런타임 분기 구현. 영구 드론, 레일 이동감속, 런처 자폭 등 최종 fidelity 및 Godot 검증 미완 |
| 16 | 총열 부품 | **PARTIAL** | 정밀/확산/관통/반사/폭발/장거리/절단/유도/분열/역추진/공명/불안정 12종의 핵심 projectile runtime 경로 구현. 탄약 25% 같은 일부 자원 규칙·밸런스·실행 QA 미완 |
| 17 | 탄창 부품 | **PARTIAL** | 대용량/경량은 stat modifier 경로, 폭발/역순/압축/재생/교차는 projectile runtime, 비상/자기/반응/도박/이중은 MagazineRuntime으로 구현. 무기교체 보너스·정확한 방 리셋/수집물 계약·UI·QA 미완 |
| 18 | 코어 부품 | **PARTIAL** | 12종 데이터. Fire/Cold/Shock/Corrosion/Bleed + Void/Impact/Absorption/Photon/Replication/Devour/Inverse Phase 실행 경로 구현; 충격 벽보너스, Devour 엘리트 지속, 지형 전도 등 fidelity/QA 미완 |
| 19 | 상태 이상 | **PARTIAL** | Burn/Cold/Shock/Corrosion/Bleed/Confusion/Vulnerable 축적·틱·동결·연쇄·피해증폭 구현, Burn+폭발 및 동결 파쇄 반응 구현; 보스 혼란 변환/물 지형/전체 QA 미완 |
| 20 | 장비 격자 시스템 | **PARTIAL** | 6×5 배치/회전/점유/인접/최대 3칸 확장 + place_item/items/are_adjacent API, 회전된 실제 단자 셀/방향 계산 구현; UI·드래그·전투중 잠금·저장 미완 |
| 21 | 패시브 모듈 | **NOT STARTED** | GDD 기준 구현 필요 |
| 22 | 액티브 장비 | **NOT STARTED** | GDD 기준 구현 필요 |
| 23 | 등급과 희귀도 | **NOT STARTED** | GDD 기준 구현 필요 |
| 24 | 시너지 시스템 | **PARTIAL** | 방향성 power/signal/ammo/cooling 단자 링크, 전력 네트워크 공급/소비/과부하, powered item, 인접 effect, tag tier 계산 구현; 정식 50종 시너지·UI·콘텐츠 검증 미완 |
| 25 | 캐릭터 | **NOT STARTED** | GDD 기준 구현 필요 |
| 26 | 방과 맵 생성 | **NOT STARTED** | GDD 기준 구현 필요 |
| 27 | 방 종류 | **NOT STARTED** | GDD 기준 구현 필요 |
| 28 | 전투 위협도 | **NOT STARTED** | GDD 기준 구현 필요 |
| 29 | 적 AI 공통 규칙 | **PARTIAL** | Chaser/Ranged AI, 상태이상 속도/동결/혼란 영향 일부 구현; 공통 인식·벽 끼임·예고 규칙 미완 |
| 30 | 제1구역: 폐기 조립라인 | **NOT STARTED** | GDD 기준 구현 필요 |
| 31 | 제1구역 보스: 폐기물 압축기 GR-01 | **NOT STARTED** | GDD 기준 구현 필요 |
| 32 | 제2구역: 생화학 처리시설 | **NOT STARTED** | GDD 기준 구현 필요 |
| 33 | 제2구역 보스: 누출된 실험체 EVE-09 | **NOT STARTED** | GDD 기준 구현 필요 |
| 34 | 제3구역: 중앙 탄약저장고 | **NOT STARTED** | GDD 기준 구현 필요 |
| 35 | 제3구역 보스: 자동포대 열차 ATLAS | **NOT STARTED** | GDD 기준 구현 필요 |
| 36 | 제4구역: 지휘 제어망 | **NOT STARTED** | GDD 기준 구현 필요 |
| 37 | 최종 보스: MOTHERLINE | **NOT STARTED** | GDD 기준 구현 필요 |
| 38 | 비밀 구역: 기억 보관소 | **NOT STARTED** | GDD 기준 구현 필요 |
| 39 | 보상 시스템 | **PARTIAL** | 방 클리어 단일 보상 프로토타입, 선택형/중복방지 미완 |
| 40 | 상자 | **NOT STARTED** | GDD 기준 구현 필요 |
| 41 | 런 내부 경제 | **NOT STARTED** | GDD 기준 구현 필요 |
| 42 | 저주 시스템 | **NOT STARTED** | GDD 기준 구현 필요 |
| 43 | 영구 성장 | **NOT STARTED** | GDD 기준 구현 필요 |
| 44 | 허브 | **NOT STARTED** | GDD 기준 구현 필요 |
| 45 | 난도 시스템 | **NOT STARTED** | GDD 기준 구현 필요 |
| 46 | 튜토리얼 | **NOT STARTED** | GDD 기준 구현 필요 |
| 47 | UI 구조 | **PARTIAL** | M1 HUD 일부, 전체 UI 우선순위/피해 숫자/프레임 charge-spin-beam 상태표시 미완 |
| 48 | 인벤토리 UI | **NOT STARTED** | GDD 기준 구현 필요 |
| 49 | 지도 UI | **NOT STARTED** | GDD 기준 구현 필요 |
| 50 | 접근성 | **NOT STARTED** | GDD 기준 구현 필요 |
| 51 | 그래픽 방향 | **NOT STARTED** | GDD 기준 구현 필요 |
| 52 | 카메라 | **PARTIAL** | 카메라 구조 미완; 흔들림/보스 카메라 미구현 |
| 53 | 이펙트 | **PARTIAL** | 기초 플래시 훅 일부, 전체 VFX 정책·빔/폭발/상태 시각 피드백 미구현 |
| 54 | 사운드 | **NOT STARTED** | GDD 기준 구현 필요 |
| 55 | 대사와 텍스트 | **NOT STARTED** | GDD 기준 구현 필요 |
| 56 | 로컬라이징 | **NOT STARTED** | GDD 기준 구현 필요 |
| 57 | 저장 시스템 | **NOT STARTED** | GDD 기준 구현 필요 |
| 58 | 통계와 도감 | **NOT STARTED** | GDD 기준 구현 필요 |
| 59 | 업적 | **NOT STARTED** | GDD 기준 구현 필요 |
| 60 | 일일 시드와 도전 | **NOT STARTED** | GDD 기준 구현 필요 |
| 61 | 밸런스 기준 | **NOT STARTED** | GDD 기준 구현 필요 |
| 62 | 무작위성 원칙 | **NOT STARTED** | GDD 기준 구현 필요 |
| 63 | 기술 구조 | **PARTIAL** | Resource/JSON + WeaponBuild/WeaponEffectResolver/MagazineRuntime/StatusReceiver/BackpackGrid/BackpackSynergyResolver 실행 계층 및 `tools/gdd_runtime_smoke.gd` 추가; 실제 headless 실행·회귀 CI 결과 미확인 |
| 64 | 성능 목표 | **NOT STARTED** | GDD 기준 구현 필요 |
| 65 | 화면 비율과 디스플레이 | **PARTIAL** | 1920x1080 기반만 존재, 비율/모드/UI 배율 미검증 |
| 66 | Steam 출시 기능 | **NOT STARTED** | GDD 기준 구현 필요 |
| 67 | 콘텐츠 목표량 | **NOT STARTED** | GDD 기준 구현 필요 |
| 68 | 게임 모드 | **NOT STARTED** | GDD 기준 구현 필요 |
| 69 | 엔딩 | **NOT STARTED** | GDD 기준 구현 필요 |
| 70 | 리플레이 가치 | **NOT STARTED** | GDD 기준 구현 필요 |
| 71 | 출시 가격과 판매 방향 | **NOT STARTED** | GDD 기준 구현 필요 |
| 72 | 개발 단계 | **NOT STARTED** | GDD 기준 구현 필요 |
| 73 | 권장 팀 구성 | **NOT STARTED** | GDD 기준 구현 필요 |
| 74 | 최소 출시 범위와 확장 범위 | **NOT STARTED** | GDD 기준 구현 필요 |
| 75 | QA 계획 | **NOT STARTED** | GDD 기준 구현 필요 |
| 76 | 주요 위험 요소 | **NOT STARTED** | GDD 기준 구현 필요 |
| 77 | 핵심 성공 기준 | **NOT STARTED** | GDD 기준 구현 필요 |
| 78 | 최종 제품 정의 | **NOT STARTED** | GDD 기준 구현 필요 |
| 79 | 최종 핵심 요약 | **NOT STARTED** | GDD 기준 구현 필요 |
| 80 | 후속 제작 문서 목록 | **NOT STARTED** | GDD 기준 구현 필요 |

## Explicit Content Count Gates

GDD 67.1 기준 목표량:

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

> 무기/부품 카탈로그에 목표 수량 데이터가 존재하더라도 실제 런 등장·효과·UI·저장·입력·QA 조건을 만족하기 전에는 위 콘텐츠 수량 게이트를 체크하지 않는다.

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

현재 코드는 GDD 전체 구현판이 아니다. 무기 프레임/총열/탄창/코어와 가방 전력망의 코드 커버리지는 크게 확장됐지만 실제 Godot 실행 검증이 끝나지 않았고, 런 구조·콘텐츠·UI·저장·플랫폼 범위 대부분이 아직 남아 있다. 따라서 사용자에게 "기획서가 완벽하게 포함된 빌드"라고 제시하면 안 된다.

## Update Rule

1. 의미 있는 코드 변경마다 해당 GDD 섹션 상태를 갱신한다.
2. `IMPLEMENTED` 전환 시 관련 파일/테스트를 Note에 기록한다.
3. 실제 실행 검증이 끝나야 `VALIDATED`로 올린다.
4. GDD와 구현이 다르면 PROJECT.md의 Design Decisions에 변경 사유와 사용자 승인 여부를 기록한다.
5. 최종 피드백 요청 전 GDD 원문과 이 매트릭스를 다시 대조해 누락 항목 0개를 확인한다.
