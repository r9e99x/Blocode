# Blocode

> 코드 블럭을 순서대로 조립해서 캐릭터를 목표 지점까지 이끄는 코딩 퍼즐 게임

코딩을 몰라도 즐길 수 있는 캐주얼 퍼즐이지만, 스테이지를 하나씩 풀다 보면 순차 실행·반복문·조건문·함수라는 프로그래밍의 핵심 개념을 자연스럽게 체득하게 되는 것을 목표로 만들었습니다. 블럭 하나하나가 실제 프로그래밍 언어의 문법과 1:1로 대응하기 때문에, 화면 속 캐릭터의 움직임이 곧 "내가 짠 코드가 실행되는 모습"이 됩니다.

SwiftUI + SpriteKit으로 작성된 iOS / iPadOS / macOS 멀티플랫폼 앱입니다.

---

## 실행 화면

<img width="320" alt="Simulator Screenshot - 16 PM 26 4 1 - 2026-07-20 at 12 56 12" src="https://github.com/user-attachments/assets/4084a60e-b366-4103-862d-d28ea79f324a" />
<img width="320" alt="Simulator Screenshot - 16 PM 26 4 1 - 2026-07-20 at 12 56 06" src="https://github.com/user-attachments/assets/7b5939db-bed3-49b4-9c89-717fd56a21da" />
<img width="320" alt="Simulator Screenshot - 16 PM 26 4 1 - 2026-07-20 at 12 56 42" src="https://github.com/user-attachments/assets/a5b83ff1-5acd-4862-9ad1-a87dafd6420e" />
<img width="320" alt="Simulator Screenshot - 16 PM 26 4 1 - 2026-07-20 at 12 56 14" src="https://github.com/user-attachments/assets/3a35c526-f903-4fb2-9f7d-450924b4a402" />


## 핵심 컨셉

- **블럭 = 코드**: 앞으로/뒤로/회전 같은 기본 동작부터, 반복(`repeat`)·조건(`if`)·함수(`function`) 같은 제어 구조까지 전부 드래그 앤 드롭 블럭으로 표현
- **별점 = 코드 품질**: 클리어 자체보다 "더 적은 블럭 수로 풀었는가"를 평가 — `repeat`로 압축할 줄 아는 사람이 더 높은 점수를 받도록 설계
- **맵 = 실행 결과의 시각화**: 캐릭터의 이동 경로가 곧 작성한 프로그램의 실행 트레이스이며, 실패 시 정확히 몇 번째 줄에서 막혔는지 하이라이트로 알려줌

## 주요 기능

- **9종 코드 블럭**: 앞으로 / 뒤로 / 좌회전 / 우회전 / 반복 / 조건문 / 함수, 그리고 챕터 6부터 등장하는 **보석 획득 / 스위치 작동** 블럭
  - `repeat` ↔ `if` 상호 중첩, 최대 3단계 중첩(자식 → 손자 → 증손자)까지 지원
- **10개 챕터, 69개 스테이지**로 구성된 커리큘럼 — 개념 하나씩 순서대로 도입되며 뒤로 갈수록 나선형 미로 등 실제로 알고리즘적 사고가 필요한 맵 등장
- **기믹 시스템**: 보석(수집), 스위치-문(개방), 포탈(순간이동) — 보석과 스위치는 정확히 그 칸에서 전용 블럭을 실행해야만 작동하고, 아무 데서나 쓰면 벽에 부딪힌 것과 동일하게 실패 처리되어 "정밀한 프로그래밍"을 요구함
- **경로 기반 실행 하이라이트**: 중첩된 블럭 안에서 실패해도 정확히 어느 블럭(부모/자식/손자 단계까지)에서 막혔는지 표시
- **진행도 시스템**: SwiftData 기반 클리어 기록/별점 저장, 챕터별 순차 해금(이전 챕터 별점 67% + 종합 스테이지 클리어)
- **라이트/다크 모드**: 전용 다이나믹 컬러 팔레트로 두 테마 모두 대응
- **크로스플랫폼**: 아이폰(세로 지그재그 챕터맵) / 아이패드·맥(가로·세로 분할 레이아웃) 화면 폭에 따라 자동 대응

## 챕터 구성

| 챕터 | 주제 | 스테이지 |
|---|---|---|
| 1. 기본기 | 이동·회전 | 6 |
| 2. 반복 | `repeat` | 8 |
| 3. 조건문 | `if` (나선형 미로) | 8 |
| 4. 함수 | `function` | 7 |
| 5. 심화 | 종합 응용 | 6 |
| 6. 보석 | 아이템 수집 블럭 | 7 |
| 7. 스위치 | 스위치-문 개방 블럭 | 7 |
| 8. 포탈 | 순간이동(자동) | 7 |
| 9. 미궁 | 기믹 복합 활용 | 7 |
| 10. 정복 | 전체 기믹 총동원 최종 보스 | 6 |

## 기술 스택

| 분야 | 기술 |
|---|---|
| UI | SwiftUI (iOS / iPadOS / macOS 공용) |
| 맵·캐릭터 렌더링 | SpriteKit (2D 탑뷰) |
| 아키텍처 | MVVM + Service 계층 + Scene 분리 |
| 동시성 | `@MainActor` 격리 (GameViewModel) |
| 진행도 저장 | SwiftData |
| 스테이지 데이터 | JSON (`ch{챕터}_stage{번호}.json`) — 코드 수정 없이 콘텐츠 추가 가능 |

## 아키텍처

```
View (SwiftUI)  ──  ViewModel  ──  Service / Model
      │
   GameScene (SpriteKit: 맵·캐릭터·기믹 렌더링)
```

- 챕터/스테이지 메타데이터는 `ChapterCatalog`에서 단일 관리 — 화면·뷰모델·서비스가 전부 이 한 곳만 참조
- 별점 계산(`flatCount`)은 `repeat`/`if`/`function` 컨테이너 자체는 세지 않고 그 안의 실제 동작 블럭만 재귀적으로 카운트
- 기믹(아이템/스위치/포탈) 필드는 전부 옵셔널이라, 기믹이 없는 스테이지 JSON은 신규 엔진에서도 완전히 동일하게 동작(하위 호환)

## 폴더 구조

```
Blocode/
├── App/            앱 진입점, 홈 화면
├── Models/         Block, ChapterCatalog, MapData, Stage 등
├── Resources/
│   └── Stages/     Chapter1~10/ ch{N}_stage{N}.json (총 69개)
├── Scene/          GameScene (SpriteKit)
├── Services/       ProgressService, SettingsService, StageLoader
├── ViewModels/      화면별 뷰모델
└── Views/
    ├── Game/       게임 플레이 화면 (맵/코드패널/팔레트)
    ├── Chapter/    챕터 선택/목록
    ├── Mac/        macOS 전용 셸
    ├── Components/ 공용 UI 컴포넌트
    ├── Onboarding/ 온보딩
    └── Settings/   설정
```

## 개발 상태

포트폴리오 및 App Store 출시를 목표로 개발 중입니다. 현재 챕터 1~10(69개 스테이지) 콘텐츠와 핵심 게임플레이는 완성되었고, 사운드/힌트 시스템·iCloud 동기화·App Store 심사 준비가 남아 있습니다.

---

개발: 조준희
