# LAST MAGAZINE — Godot Production Project

Godot 4.7.1 기반 정식 이식 프로젝트입니다. 루트의 HTML5 Canvas 빌드는 모바일 피드백용으로 유지하며, 이 폴더가 Windows·Linux·Steam·향후 Android 정식 빌드의 기준 소스입니다.

## 실행

1. Godot 4.7.1 Standard를 설치합니다.
2. Godot Project Manager에서 `godot/project.godot`을 엽니다.
3. `F6`가 아니라 `F5`로 메인 프로젝트를 실행합니다.

현재 메인 씬은 외부 그래픽·사운드가 없어도 실행되는 절차형 전투 수직 슬라이스입니다.

## 현재 구현

- 키보드·마우스 및 Xbox/PlayStation/Steam Deck 계열 공통 InputMap
- 이동, 조준, 사격, 재장전, 대시, 무적 시간
- 일반 적 추적·사격·궤도 이동·돌진 AI
- 플레이어·적 투사체, 관통, 접촉 피해
- 다단계 보스 탄막과 보스 보상
- 체력, 방어판, 탄약, 점수, 레벨, 게임 오버
- 5캐릭터, 12무기, 36핵심 부품, 60모듈, 20액티브
- 32일반 적, 5보스, 120방, 35이벤트, 50시너지, 45업적 데이터
- 세 개 저장 슬롯, 체크섬, 백업, 마지막 런 기록
- Steam 업적·클라우드·리더보드용 오프라인 안전 어댑터
- Music/SFX/Voice 오디오 버스와 재생 풀
- Windows, Linux, Web 내보내기 프리셋

## 조작

- 이동: `WASD`, 방향키, 왼쪽 스틱
- 조준: 마우스, 오른쪽 스틱
- 발사: 마우스 왼쪽, 오른쪽 트리거
- 보조 공격: 마우스 오른쪽, 왼쪽 트리거
- 대시: `Space`, B/Circle
- 재장전: `R`, X/Square
- 액티브: `Q`, RB/R1
- 상호작용: `E`, A/Cross
- 지도: `Tab`, Back/Share
- 일시정지: `Esc`, Start/Options

## 다음 구현 순서

1. 런 준비 UI와 캐릭터 선택
2. 데이터 기반 방 그래프와 구역 전환
3. 무기 프레임·총열·탄창·코어 조립 UI
4. 6×5 가방, 회전, 단자 연결, 시너지 계산
5. 상점·제작실·의료실·사건·비밀방
6. 픽셀 아트 교체 및 애니메이션 상태기계
7. 정식 음악·효과음, 진동, 접근성 옵션
8. GodotSteam 확장 설치 후 Steamworks 실제 App ID 연결
9. Android 가상 조이스틱과 APK/AAB 내보내기
10. 밸런스·성능·세이브 호환·플랫폼 QA

## Steam 연동

`autoload/steam_integration.gd`는 Steam 싱글톤이 없는 개발 환경에서는 자동으로 오프라인 모드가 됩니다. 실제 배포 시 GodotSteam 또는 호환 GDExtension을 설치하고 Steamworks App ID, 업적 API 이름, 클라우드 할당량과 리더보드 이름을 Steamworks 백엔드에 등록해야 합니다.

## 검증

GitHub Actions의 `godot-validate.yml`이 Godot 4.7.1 headless 편집기 로딩과 짧은 런타임 부팅을 검사합니다. 외부 에셋을 추가할 때는 임포트 오류와 라이선스를 함께 확인해야 합니다.
