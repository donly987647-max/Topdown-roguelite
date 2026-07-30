# Risk Register

| ID | Risk | Window | Severity | Mitigation | Backlog controls |
|---|---|---|---|---|---|
| R01 | System overload | P2/P3 | High | 부품 수 제한, 자동 추천, 3단계 설명, 점진 해금 | P2-GATE-001, P3-TUTORIAL-001, P3-INVENTORY-UI-001 |
| R02 | Combination explosion | P2~P5 | Critical | 공통 ICD, 발동 횟수 제한, 재귀 방지, 자동 조합 테스트 | P2-EFFECT-001, P2-TEST-001, P5-COMBO-QA-001 |
| R03 | Content production volume | P3~P5 | High | 방 모듈화, 역할별 AI, 공통 애니메이션, 보스 우선 | P3-Z1-ROOM-001, P4-ROOM-COUNT-001, P5-CONTENT-001 |
| R04 | Combat readability | P1~P6 | Critical | 색상 규칙, 외곽선, 명도 제한, 파티클 상한, 위험 우선 렌더 | P1-HIT-001, P3-VFX-001, P5-ACCESS-001 |
| R05 | RNG dependency | P2~P5 | High | 선택 보상, 재등장 제한, 상점/제작, 태그 가중치, 불운 완화 | P2-REWARD-001, P4-REWARD-001, P5-RNG-001 |
| R06 | Save corruption | P3~P6 | Critical | 원자적 쓰기, 백업, 체크섬, 마이그레이션, 강제 종료 테스트 | P3-SAVE-001, P4-SAVE-001, P6-SAVE-001 |
| R07 | Performance under projectile load | P3~P6 | Critical | 풀링, 배치 처리, 화면 밖 감소, 예산 경고, 최소 사양 인증 | P3-PERF-001, P5-PERF-001, P6-PERF-001 |
| R08 | Scope expansion before validation | All | Critical | 단계 게이트와 다음 단계 차단 규칙 | P1-GATE-001~P6-GATE-001 |