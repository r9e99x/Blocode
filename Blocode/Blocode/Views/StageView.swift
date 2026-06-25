//
//  StageView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI
import SpriteKit

// MARK: - StageView
/// 스테이지 게임 화면
/// 상단 네비게이션 + 맵(SpriteKit) + 스테이지 정보 + 코드 패널로 구성
struct StageView: View {

    /// 현재 스테이지 데이터 — 원본은 ViewModel이 보유 (로딩 책임도 VM)
    private var stage: Stage { viewModel.stage }

    @StateObject private var viewModel: GameViewModel  // 게임 로직 ViewModel
    @State private var scene: GameScene?               // SpriteKit 씬 참조

    /// 루트 NavigationStack 경로 — 뒤로가기 및 다음 스테이지 이동에 사용
    @Binding var navPath: NavigationPath

    // Drag-and-drop 상태 — 팔레트에서 코드 리스트로 드래그 삽입
    // (ghost block 오버레이가 최상위 ZStack에 렌더링되므로 StageView에서 관리)
    @State private var dragType: BlockType? = nil        // 드래그 중인 블럭 타입 (nil이면 비활성)
    @State private var dragPosition: CGPoint = .zero     // 드래그 현재 글로벌 좌표
    @State private var dragInsertIndex: Int = 0          // 삽입될 예상 인덱스
    @State private var codeListFrame: CGRect = .zero     // 코드 리스트 영역의 글로벌 프레임
    @State private var rowMidYs: [Int: CGFloat] = [:]   // 각 행의 글로벌 중간 Y 좌표

    /// 코드 패널 확장 여부 — stageInfoBar 표시와 연동되므로 StageView에서 관리
    @State private var isPanelExpanded = true

    @Environment(\.colorScheme) private var colorScheme  // 다크/라이트 모드 감지

    /// 프로덕션 진입점 — 챕터/스테이지 번호만 받고 로딩은 ViewModel(VM)이 수행
    /// (View 계층에서 데이터 소스(StageLoader)를 직접 호출하지 않음 = 정석 MVVM)
    init(chapter: Int, number: Int, navPath: Binding<NavigationPath>) {
        self._navPath = navPath
        _viewModel = StateObject(wrappedValue: GameViewModel(chapter: chapter, stageNumber: number))
    }

    /// 프리뷰/테스트용 — Stage를 직접 주입 (#Preview 전용)
    init(stage: Stage, navPath: Binding<NavigationPath>) {
        self._navPath = navPath
        _viewModel = StateObject(wrappedValue: GameViewModel(stage: stage))
    }

    // MARK: - Body (로딩 성공/실패 분기)

    var body: some View {
        if viewModel.loadFailed {
            // 스테이지 로딩 실패 — 빈 화면 대신 폴백 UI (정상 콘텐츠에서는 절대 진입 안 함)
            stageLoadFailedView
        } else {
            loadedBody
        }
    }

    /// 스테이지 로딩 실패 시 표시되는 폴백 화면
    private var stageLoadFailedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.45))
            Text("스테이지를 불러올 수 없어요")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            Text("데이터가 없거나 손상됐어요.\n잠시 후 다시 시도해주세요.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if !navPath.isEmpty { navPath.removeLast() }  // 이전 화면으로 복귀
            } label: {
                Text("돌아가기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.darkInk)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var loadedBody: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {

                // MARK: 상단 네비게이션
                navigationBar

                // MARK: 맵 영역 — GeometryReader로 너비를 읽어 정사각형 고정
                GeometryReader { geo in
                    mapView
                        .frame(width: geo.size.width, height: geo.size.width)
                }
                .aspectRatio(1.0, contentMode: .fit)  // 항상 정사각형 유지
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // MARK: 스테이지 정보 바 — 패널 축소 시에만 표시
                if !isPanelExpanded {
                    stageInfoBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 0)

                // MARK: 코드 영역 + 팔레트 + 컨트롤
                CodePanelView(
                    viewModel: viewModel,
                    stage: stage,
                    dragType: $dragType,
                    dragPosition: $dragPosition,
                    dragInsertIndex: $dragInsertIndex,
                    codeListFrame: $codeListFrame,
                    rowMidYs: $rowMidYs,
                    navPath: $navPath,
                    isPanelExpanded: $isPanelExpanded
                )
            }

            // MARK: 실패 토스트 오버레이 — 상단에서 내려오는 배너
            if viewModel.gameState == .failure {
                failureToast
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // MARK: 클리어 오버레이 — 전체 화면 덮기
            if viewModel.gameState == .success {
                ClearOverlayView(
                    stars: viewModel.clearedStars,
                    elapsedTime: viewModel.elapsedTime,
                    attemptCount: viewModel.attemptCount,
                    blockCount: viewModel.totalBlockCount,
                    stageLabel: "\(stage.chapter)-\(stage.stageNumber)",
                    stageName: stage.name,
                    threeStarCut: stage.starThresholds.threeStar,
                    isLastStage: !viewModel.hasNextStage,
                    onClose: {
                        // 닫기 → 챕터 화면으로 이동 (빈 스택이면 무시 — 언더플로우 방지)
                        if !navPath.isEmpty { navPath.removeLast() }
                    },
                    onRetry: {
                        // 다시 도전 → 블럭 유지, 캐릭터만 리셋
                        viewModel.fullReset()
                    },
                    onNext: {
                        // 다음 스테이지 → 현재 스테이지 pop 후 다음 스테이지 push
                        // 별 3개 + 마지막 스테이지: 챕터 선택 화면까지 2번 pop
                        viewModel.reset()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            if viewModel.hasNextStage {
                                if !navPath.isEmpty { navPath.removeLast() }
                                navPath.append(AppRoute.stage(
                                    chapter: stage.chapter,
                                    number: stage.stageNumber + 1
                                ))
                            } else {
                                // 마지막(종합) 스테이지를 별 3개로 클리어 → "챕터 목록으로"
                                // 진입 경로(홈 바로 시작 / 챕터 둘러보기)와 무관하게
                                // 항상 챕터 선택 화면으로 결정적 이동 (pop 횟수 의존 제거)
                                navPath = NavigationPath()
                                navPath.append(AppRoute.chapterSelect)
                            }
                        }
                    },
                    onFinish: {
                        // 마무리 버튼 (별 1~2개 + 마지막/종합 스테이지):
                        // 진입 경로와 무관하게 항상 챕터 선택 화면으로 결정적 이동
                        navPath = NavigationPath()
                        navPath.append(AppRoute.chapterSelect)
                    }
                )
                .transition(.opacity)
            }

            // MARK: Ghost drag block — 모든 UI 위에 렌더링
            if let type = dragType {
                ghostBlock(type: type, at: dragPosition)
            }
        }
        // 각 행의 중간 Y 좌표를 preference로 수집 (드래그 삽입 인덱스 계산용)
        .onPreferenceChange(RowMidYKey.self) { midYs in
            rowMidYs = midYs
        }
        .animation(.spring(duration: 0.3), value: viewModel.gameState)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { setupScene() }  // 씬 초기화
        // 색상 모드 변경 시 씬 색상 갱신
        .onChange(of: colorScheme) { _, newScheme in
            scene?.updateColorScheme(isDark: newScheme == .dark)
        }
        .navigationBarHidden(true)
    }

    // MARK: - 상단 네비게이션 바

    private var navigationBar: some View {
        HStack(alignment: .center, spacing: 12) {

            // 뒤로가기 버튼 (그림자 있는 카드 버튼)
            Button {
                if !navPath.isEmpty { navPath.removeLast() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(Color.panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            // 스테이지 제목 — 스테이지 번호 + 이름
            VStack(alignment: .leading, spacing: 2) {
                // "STAGE 1-3" 형식 서브타이틀
                Text("STAGE \(stage.chapter)-\(stage.stageNumber)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                // 스테이지 이름
                Text(stage.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            // 별점 표시 — 클리어 후 획득한 별 수 반영
            StarRatingView(earned: viewModel.clearedStars, size: 13)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - SpriteKit 맵 뷰

    private var mapView: some View {
        Group {
            if let scene = scene {
                // 씬이 준비됐으면 SpriteView 표시
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(Color.mapBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        // 맵 테두리
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.separatorColor, lineWidth: 1)
                    )
            } else {
                // 씬 로딩 중: 배경 + 로딩 인디케이터
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.mapBackground)
                    .overlay(ProgressView())
            }
        }
    }

    // MARK: - 스테이지 정보 바 (목표 + 별 기준)

    /// 패널 최소화 시 보이는 스테이지 이름 + 별 기준 정보
    private var stageInfoBar: some View {
        VStack(spacing: 6) {
            // 스테이지 이름 — 크고 굵게, 가운데 정렬
            Text(stage.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            // 별 기준 요약 — "★★★ N블럭 이하  —  ★★☆ M블럭 이하"
            Text("★★★ \(stage.starThresholds.threeStar)블럭 이하  —  ★★☆ \(stage.starThresholds.twoStar)블럭 이하")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: 드래그 고스트 블럭

    /// 드래그 중 손가락 위치에 표시되는 반투명 고스트 블럭
    private func ghostBlock(type: BlockType, at position: CGPoint) -> some View {
        VStack(spacing: 5) {
            Image(systemName: type.iconName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(type.displayName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 72, height: 72)
        .background(type.blockColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: type.blockColor.opacity(0.5), radius: 14, y: 6)
        .scaleEffect(1.1)  // 손가락 위에 살짝 크게
        .position(x: position.x, y: position.y - 50)  // 손가락 위쪽에 표시
        .allowsHitTesting(false)  // 고스트 블럭은 터치 통과
        .transition(.scale(scale: 0.7).combined(with: .opacity))
        .animation(.spring(duration: 0.2), value: dragType != nil)
    }

    // MARK: - 실패 토스트 배너

    /// 실행 실패 시 상단에서 내려오는 빨간 배너
    private var failureToast: some View {
        HStack(spacing: 12) {
            // 실패 아이콘
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 20))
                .foregroundStyle(.white)

            // 실패 메시지 (예: "벽에 부딪혔어요 · 라인 3")
            Text(viewModel.failureMessage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            // 리셋 버튼 — 캐릭터를 시작 위치로 되돌림
            Button("리셋") {
                viewModel.reset()
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.25))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.red.opacity(0.92)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.red.opacity(0.3), radius: 10, y: 4)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - 씬 초기화

    /// GameScene을 생성하고 ViewModel과 연결
    private func setupScene() {
        // 이미 씬이 있으면 재생성하지 않음 — 설정 fullScreenCover가 닫히며
        // onAppear가 다시 호출돼도 맵/캐릭터 상태가 초기화되지 않도록 가드
        guard scene == nil else { return }
        let gameScene = GameScene(mapData: stage.mapData)
        // 현재 색상 모드에 맞춰 씬 색상 설정
        gameScene.updateColorScheme(isDark: colorScheme == .dark)
        // ViewModel에 씬 참조 전달 (캐릭터 이동 명령용)
        viewModel.scene = gameScene
        self.scene = gameScene
    }
}

// MARK: - RowMidY PreferenceKey
/// 각 블럭 행의 글로벌 중간 Y 좌표를 상위 뷰로 전달하기 위한 PreferenceKey
struct RowMidYKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    /// 여러 행의 값을 병합 — 나중에 온 값이 우선 (같은 키면 새 값으로 덮어씀)
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Preview용 샘플 데이터

extension Stage {
    /// 간단한 3×3 직선 맵 스테이지 (프리뷰용)
    static var preview: Stage {
        Stage(
            id: "ch1_stage1",
            chapter: 1,
            stageNumber: 1,
            name: "첫 걸음",
            mapData: MapData(
                grid: [
                    [0, 1, 0],
                    [0, 1, 0],
                    [0, 1, 0]
                ],
                start: Position(x: 1, y: 2),
                startDirection: .up,
                goal: Position(x: 1, y: 0)
            ),
            starThresholds: StarThresholds(threeStar: 2, twoStar: 4)
        )
    }

    /// 복잡한 5×5 미로 스테이지 (프리뷰용)
    static var previewComplex: Stage {
        Stage(
            id: "ch1_stage5",
            chapter: 1,
            stageNumber: 5,
            name: "뒤로 한 칸",
            mapData: MapData(
                grid: [
                    [0, 0, 1, 1, 1],
                    [0, 0, 1, 0, 1],
                    [1, 1, 1, 0, 1],
                    [1, 0, 0, 0, 1],
                    [1, 1, 0, 1, 1]
                ],
                start: Position(x: 0, y: 2),
                startDirection: .up,
                goal: Position(x: 4, y: 0)
            ),
            starThresholds: StarThresholds(threeStar: 4, twoStar: 6)
        )
    }
}

#Preview("첫 걸음") {
    @Previewable @State var path = NavigationPath()
    StageView(stage: .preview, navPath: $path)
}

#Preview("뒤로 한 칸") {
    @Previewable @State var path = NavigationPath()
    StageView(stage: .previewComplex, navPath: $path)
}
