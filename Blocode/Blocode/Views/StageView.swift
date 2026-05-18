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

    let stage: Stage  // 현재 스테이지 데이터

    @StateObject private var viewModel: GameViewModel  // 게임 로직 ViewModel
    @State private var scene: GameScene?               // SpriteKit 씬 참조

    /// 루트 NavigationStack 경로 — 뒤로가기 및 다음 스테이지 이동에 사용
    @Binding var navPath: NavigationPath

    // Drag-and-drop 상태 — 팔레트에서 코드 리스트로 드래그 삽입
    @State private var dragType: BlockType? = nil        // 드래그 중인 블럭 타입 (nil이면 비활성)
    @State private var dragPosition: CGPoint = .zero     // 드래그 현재 글로벌 좌표
    @State private var dragInsertIndex: Int = 0          // 삽입될 예상 인덱스
    @State private var codeListFrame: CGRect = .zero     // 코드 리스트 영역의 글로벌 프레임
    @State private var rowMidYs: [Int: CGFloat] = [:]   // 각 행의 글로벌 중간 Y 좌표

    /// 설정 시트 표시 여부
    @State private var showSettings = false

    /// 코드 패널 확장 여부 (기본: 확장)
    @State private var isPanelExpanded  = true
    @State private var isResetPressed    = false  // 리셋 버튼 눌림 상태
    @State private var isRunPressed      = false  // 실행 버튼 눌림 상태
    @State private var isSettingsPressed = false  // 설정 버튼 눌림 상태

    @Environment(\.colorScheme) private var colorScheme  // 다크/라이트 모드 감지

    init(stage: Stage, navPath: Binding<NavigationPath>) {
        self.stage = stage
        self._navPath = navPath
        // 스테이지 데이터로 GameViewModel 초기화
        _viewModel = StateObject(wrappedValue: GameViewModel(stage: stage))
    }

    /// 다음 스테이지 존재 여부 — 챕터 마지막 스테이지이면 false
    private var hasNextStage: Bool {
        StageLoader.load(chapter: stage.chapter, stage: stage.stageNumber + 1) != nil
    }

    /// 코드 패널 카드 배경 — 다크/라이트 모드 대응
    private var panelBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
                : UIColor(red: 0.984, green: 0.965, blue: 0.910, alpha: 1.0)
        })
    }

    var body: some View {
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
                codePanel
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
                    isLastStage: !hasNextStage,
                    onClose: {
                        // 닫기 → 챕터 화면으로 이동
                        navPath.removeLast()
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
                            if hasNextStage {
                                navPath.removeLast()
                                navPath.append(AppRoute.stage(
                                    chapter: stage.chapter,
                                    number: stage.stageNumber + 1
                                ))
                            } else {
                                // 마지막 스테이지(별 3개): stage → chapter → chapterSelect 2번 pop
                                navPath.removeLast()
                                navPath.removeLast()
                            }
                        }
                    },
                    onFinish: {
                        // 마무리 버튼 (별 1~2개 + 마지막 스테이지): 스테이지 목록으로 1번 pop
                        navPath.removeLast()
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
                navPath.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(panelBackground)
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
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < viewModel.clearedStars ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            i < viewModel.clearedStars
                                ? Color(red: 0.95, green: 0.72, blue: 0.28)  // 골드
                                : Color.tertiaryLabelColor                    // 연한 빈 별
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - SpriteKit 맵 뷰

    private var mapView: some View {
        // 맵 배경색 — 다크/라이트 모드에 따라 다른 색상
        let mapBackground: Color = colorScheme == .dark
            ? Color(red: 0.10, green: 0.12, blue: 0.18)
            : Color(red: 239/255, green: 229/255, blue: 205/255) // #efe5cd

        return Group {
            if let scene = scene {
                // 씬이 준비됐으면 SpriteView 표시
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(mapBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        // 맵 테두리
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.separatorColor, lineWidth: 1)
                    )
            } else {
                // 씬 로딩 중: 배경 + 로딩 인디케이터
                RoundedRectangle(cornerRadius: 20)
                    .fill(mapBackground)
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

    // MARK: - 코드 패널 (리스트 + 팔레트 + 컨트롤)

    private var codePanel: some View {
        VStack(spacing: 0) {

        // ── 패널 카드 (핸들 + 코드 리스트) ──
        VStack(spacing: 0) {

            // 드래그 핸들 — 탭으로 패널 확장/최소화 토글
            dragHandle

            if isPanelExpanded {
                // ─── 확장 상태: 코드 리스트 헤더 + 리스트 ───
                codeListHeader   // 헤더 (CODE 레이블 + 블럭 수 + 별 기준)
                codeBlockList    // 블럭 목록 (List 또는 빈 상태 안내)
                Spacer(minLength: 8)
            } else {
                // ─── 최소화 상태: 가로 칩 요약 ───
                collapsedChipRow  // 블럭 미니 칩 가로 스크롤
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 6)
            }

        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 2)
        .animation(.spring(duration: 0.3), value: isPanelExpanded)

        // ── 팔레트 (카드 밖, 앱 배경에 직접) ──
        VStack(spacing: 4) {
            // "PALETTE" 레이블
            HStack {
                Text("PALETTE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 20)

            // 블럭 팔레트 — 탭 추가 / 드래그 삽입 지원
            PaletteView(
                onSelect: { type in
                    // 탭: 코드 리스트 맨 뒤에 추가
                    viewModel.addBlock(type)
                },
                onDragStart: { type, pt in
                    // 드래그 시작: idle 상태일 때만 허용
                    guard viewModel.gameState == .idle else { return }
                    withAnimation(.spring(duration: 0.2)) {
                        dragType = type
                        dragPosition = pt
                        dragInsertIndex = calculateInsertIndex(for: pt.y)
                    }
                },
                onDragChange: { type, pt in
                    // 드래그 중: 위치와 삽입 인덱스 갱신
                    dragPosition = pt
                    dragInsertIndex = calculateInsertIndex(for: pt.y)
                },
                onDragEnd: { type, pt in
                    // 드래그 종료: 계산된 인덱스에 블럭 삽입
                    if dragType != nil {
                        withAnimation(.spring(duration: 0.2)) {
                            viewModel.insertBlock(type, at: dragInsertIndex)
                        }
                    }
                    withAnimation(.spring(duration: 0.2)) {
                        dragType = nil  // 고스트 블럭 제거
                    }
                }
            )
            // 실행 중에는 팔레트 비활성화 + 흐리게
            .allowsHitTesting(viewModel.gameState != .running)
            .opacity(viewModel.gameState == .running ? 0.4 : 1.0)
        }
        .padding(.top, 8)

        // 컨트롤 바 — 앱 배경에 직접 배치
        controlBar
            .padding(.top, 6)
            .padding(.bottom, 24)

        } // outer VStack
    }

    // MARK: 드래그 핸들 (확장/최소화 토글)

    private var dragHandle: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                isPanelExpanded.toggle()
            }
        } label: {
            // 확장 상태: 아래 화살표 / 최소화 상태: 위 화살표
            Image(systemName: isPanelExpanded ? "chevron.down" : "chevron.up")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.28))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }

    // MARK: 코드 리스트 헤더

    /// "CODE" 레이블 + 현재 블럭 수 뱃지 + 별 3개 기준
    private var codeListHeader: some View {
        HStack {
            // "CODE" 레이블
            Text("CODE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            // 현재 총 블럭 수 캡슐 뱃지
            Text("\(viewModel.totalBlockCount)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.tertiaryBackground)
                .clipShape(Capsule())

            Spacer()

            // 별 3개 기준 블럭 수 표시
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(red: 0.95, green: 0.72, blue: 0.28))
                Text("3 = \(stage.starThresholds.threeStar) blocks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    // MARK: 코드 블럭 리스트

    /// 사용자가 추가한 코드 블럭을 세로 리스트로 표시
    private var codeBlockList: some View {
        Group {
            if viewModel.codeBlocks.isEmpty {
                // 블럭이 없을 때 안내 메시지
                VStack(spacing: 6) {
                    Image(systemName: "plus.square.dashed")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.tertiaryLabelColor)
                    Text("아래 팔레트에서 블럭을 추가하세요")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                List {
                    ForEach(Array(viewModel.codeBlocks.enumerated()), id: \.element.id) { offset, block in
                        // 드래그 삽입 인디케이터 — 첫 번째 위치
                        if dragType != nil && dragInsertIndex == 0 && offset == 0 {
                            insertionIndicator(color: dragType!.blockColor)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        }

                        // 블럭 행 뷰
                        BlockRowView(
                            block: block,
                            index: offset,
                            // 실행 중이고 현재 인덱스와 일치하면 활성 표시
                            isActive: viewModel.currentBlockIndex == offset && viewModel.gameState == .running,
                            isFailed: viewModel.failedBlockIndex == offset,
                            onDelete: { viewModel.removeBlock(at: offset) },
                            onAddChild: { childType in
                                viewModel.addChildBlock(childType, to: offset)
                            },
                            onRemoveChild: { childIndex in
                                viewModel.removeChildBlock(at: childIndex, from: offset)
                            },
                            onRepeatCountChange: { count in
                                viewModel.setRepeatCount(count, at: offset)
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        // 각 행의 중간 Y 좌표를 preference로 보고 (드래그 인덱스 계산용)
                        .background(GeometryReader { geo in
                            Color.clear.preference(
                                key: RowMidYKey.self,
                                value: [offset: geo.frame(in: .global).midY]
                            )
                        })

                        // 드래그 삽입 인디케이터 — 현재 블럭 다음 위치
                        if dragType != nil && dragInsertIndex == offset + 1 {
                            insertionIndicator(color: dragType!.blockColor)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(height: 160)  // 패널 확장 시 고정 높이
        // 코드 리스트 글로벌 프레임 추적 (드래그 감지용)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { codeListFrame = geo.frame(in: .global) }
                .onChange(of: geo.size) { codeListFrame = geo.frame(in: .global) }
        })
    }

    // MARK: 최소화 상태 칩 요약 뷰

    /// 패널 최소화 시 블럭들을 작은 칩 형태로 가로 스크롤로 표시
    private var collapsedChipRow: some View {
        HStack(spacing: 0) {
            // 가로 스크롤 칩 행
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if viewModel.codeBlocks.isEmpty {
                        // 블럭 없음 안내
                        Text("블럭 없음")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    } else {
                        // 각 블럭을 작은 칩으로 표시
                        ForEach(Array(viewModel.codeBlocks.enumerated()), id: \.element.id) { _, block in
                            blockChip(block)
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.leading, 16)
            }

            // 블럭 수 뱃지 — 스크롤 영역 오른쪽에 고정
            HStack(spacing: 4) {
                Text("\(viewModel.totalBlockCount)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.tertiaryBackground)
                    .clipShape(Capsule())
                Text("blocks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
        }
        .frame(height: 36)
    }

    /// 블럭 하나를 작은 캡슐 칩으로 표시 — 아이콘 (+ repeat 횟수)
    private func blockChip(_ block: Block) -> some View {
        HStack(spacing: 3) {
            Image(systemName: block.type.shortIconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            // repeat 블럭은 반복 횟수도 표시
            if block.type == .repeatBlock {
                Text("×\(block.repeatCount ?? 2)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(block.type.blockColor)
        .clipShape(Capsule())
    }

    // MARK: - 컨트롤 바 (되돌리기 | 실행 | 설정)

    /// 실행 버튼 색상 — 비활성/실행 중: 회색 / 활성: 민트 그린
    private var runButtonColor: Color {
        viewModel.codeBlocks.isEmpty || viewModel.gameState == .running
            ? Color(red: 0.72, green: 0.70, blue: 0.67) // 솔리드 따뜻한 회색 — 3D 효과가 잘 보이도록
            : Color(red: 0.27, green: 0.72, blue: 0.58)  // 민트 그린 (활성)
    }

    private var controlBar: some View {
        HStack(spacing: 0) {

            // 왼쪽: 리셋 / 전체 초기화 버튼
            Button {
                if viewModel.characterMoved { viewModel.reset() }
                else { viewModel.fullReset() }
            } label: {
                button3D(color: panelBackground, width: 54, height: 54, cornerRadius: 17, isPressed: isResetPressed) {
                    Image(systemName: viewModel.characterMoved ? "arrow.uturn.backward" : "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gameState == .running)
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { isResetPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.08)) { isResetPressed = false } }
            )
            .frame(maxWidth: .infinity)

            // 가운데: 실행 버튼
            Button { viewModel.run() } label: {
                button3D(color: runButtonColor, width: 152, height: 54, cornerRadius: 27, isPressed: isRunPressed) {
                    HStack(spacing: 8) {
                        if viewModel.gameState == .running {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text(viewModel.gameState == .running ? "실행 중" : "실행")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!(viewModel.codeBlocks.isEmpty || viewModel.gameState == .running))
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { isRunPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.08)) { isRunPressed = false } }
            )
            .animation(.easeInOut(duration: 0.15), value: viewModel.gameState)

            // 오른쪽: 설정 버튼
            Button { showSettings = true } label: {
                button3D(color: panelBackground, width: 54, height: 54, cornerRadius: 17, isPressed: isSettingsPressed) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gameState == .running)
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { isSettingsPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.08)) { isSettingsPressed = false } }
            )
            .frame(maxWidth: .infinity)
            // 설정 화면 — 진행도 초기화 시 홈으로 이동
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(onResetProgress: {
                    navPath = NavigationPath()  // 스택 초기화로 홈 복귀
                })
                .preferredColorScheme(SettingsService.shared.theme.colorScheme)
            }
        }
        .padding(.horizontal, 20)
    }

    /// 3D 버튼 — 챕터/스테이지 버튼과 동일한 3레이어 구조
    /// isPressed = true 시 뒷면 사라지고 앞면이 중앙으로 이동
    @ViewBuilder
    private func button3D<Content: View>(
        color: Color,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        topDepth: CGFloat = 2,
        botDepth: CGFloat = 2.5,
        isPressed: Bool = false,
        @ViewBuilder label: () -> Content
    ) -> some View {
        ZStack(alignment: .top) {
            // ① 위 뒷면 — 눌리면 사라짐
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.white.opacity(0.28))
            }
            .frame(width: width, height: height)
            .opacity(isPressed ? 0 : 1)

            // ② 아래 뒷면 — 눌리면 사라짐
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(0.22))
            }
            .frame(width: width, height: height)
            .offset(y: topDepth + botDepth)
            .opacity(isPressed ? 0 : 1)

            // ③ 앞면 — 눌리면 아래 뒷면 자리까지 완전히 내려감
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                // 눌렸을 때 살짝 어두워지는 오버레이
                if isPressed {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(0.10))
                }
                label()
            }
            .frame(width: width, height: height)
            .offset(y: isPressed ? topDepth + botDepth : topDepth)
        }
        .frame(width: width, height: height + topDepth + botDepth)
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

    // MARK: 삽입 인디케이터

    /// 드래그 중 삽입 위치를 표시하는 가로 선 + 도트
    private func insertionIndicator(color: Color) -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(color)
                .frame(height: 2)
        }
        .padding(.horizontal, 12)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.15), value: dragInsertIndex)
    }

    // MARK: 드래그 삽입 인덱스 계산

    /// 드래그 Y 좌표를 기반으로 삽입될 인덱스 계산
    private func calculateInsertIndex(for globalY: CGFloat) -> Int {
        if rowMidYs.isEmpty { return 0 }
        // 인덱스 오름차순으로 정렬
        let sorted = rowMidYs.sorted { $0.key < $1.key }
        // 드래그 위치가 행 중간 Y보다 위면 해당 행 앞에 삽입
        for (i, entry) in sorted.enumerated() {
            if globalY < entry.value { return i }
        }
        // 모든 행보다 아래면 맨 뒤에 삽입
        return sorted.count
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
private struct RowMidYKey: PreferenceKey {
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
