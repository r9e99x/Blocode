//
//  CustomMapListView.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import SwiftUI

// MARK: - CustomMapThumbnail
/// 내 맵 목록의 작은 미리보기 — 바닥과 벽, 시작·목표, 보석만 단순하게 그림
struct CustomMapThumbnail: View {

    let map: MapData?

    var body: some View {
        Canvas { context, size in
            guard let map else { return }
            let layout = EditorGridLayout(size: size, cols: map.width, rows: map.height, inset: 4)
            for y in 0..<map.height {
                for x in 0..<map.width {
                    let position = Position(x: x, y: y)
                    let rect = layout.rect(of: position).insetBy(dx: 0.5, dy: 0.5)
                    let path = Path(roundedRect: rect, cornerRadius: layout.cell * 0.2)
                    context.fill(path, with: .color(map.isFloor(position) ? .mapTileFloor : .mapTileWall))
                }
            }
            // Swift 6 모드에서 컴파일러가 이 지역 함수를 메인 액터 밖으로 봐서, 격자 계산(메인 액터)을 부르도록 격리를 명시
            @MainActor func dot(_ position: Position, color: Color, scale: CGFloat) {
                let rect = layout.rect(of: position)
                let radius = layout.cell * scale
                context.fill(Path(ellipseIn: CGRect(x: rect.midX - radius, y: rect.midY - radius,
                                                    width: radius * 2, height: radius * 2)), with: .color(color))
            }
            for item in map.items ?? [] { dot(item, color: .gemMint, scale: 0.28) }
            dot(map.goal, color: .mapGoal, scale: 0.38)
            dot(map.start, color: .characterBody, scale: 0.38)
        }
        .background(Color.mapBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.separatorColor, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

// MARK: - CustomMapListView
/// 내 맵 목록 — 만든 맵을 플레이·수정·삭제하고 새 맵을 만드는 화면
/// 아이폰은 뒤로가기가 있는 전체 화면, 아이패드·맥은 사이드바 옆 콘텐츠 패널로 쓰임(onBack이 nil)
struct CustomMapListView: View {

    @State private var vm: CustomMapListViewModel

    /// 뒤로가기 — nil이면 뒤로가기 버튼을 그리지 않음 (사이드바 셸에 들어갈 때)
    let onBack: (() -> Void)?
    let onNew: () -> Void
    let onPlay: (UUID) -> Void
    let onEdit: (UUID) -> Void

    @State private var deleteTarget: CustomMapListViewModel.Row?

    init(service: CustomMapService? = nil, onBack: (() -> Void)? = nil,
         onNew: @escaping () -> Void, onPlay: @escaping (UUID) -> Void, onEdit: @escaping (UUID) -> Void) {
        // 식을 바로 넘겨야 처음 한 번만 만들어짐 (먼저 만들어 넘기면 화면이 다시 만들어질 때마다 버려질 객체가 생김)
        _vm = State(initialValue: CustomMapListViewModel(service: service))
        self.onBack = onBack
        self.onNew = onNew
        self.onPlay = onPlay
        self.onEdit = onEdit
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if vm.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .overlay {
            if let target = deleteTarget { deleteConfirm(target) }
        }
        .hideNavigationBar()
    }

    // MARK: - 머리글

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button {
                    SoundService.shared.play(.buttonTap)
                    onBack()
                } label: {
                    CardIconLabel(icon: "chevron.left", fontSize: 15, background: .cardBackground, shadowOpacity: 0.08, shadowY: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("직접 만든 퍼즐")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("my maps")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(.primary)
            }

            Spacer()

            if !vm.isEmpty {
                Button {
                    SoundService.shared.play(.buttonTap)
                    onNew()
                } label: {
                    Label("새 맵", systemImage: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(Color.slateButtonFace)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 16)
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "square.and.pencil")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.35))
            Text("첫 맵을 만들어 보세요")
                .font(.system(size: 18, weight: .bold))
            Text("벽과 길을 그리고 보석·스위치·포탈을 놓아\n나만의 퍼즐을 만들 수 있어요.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            EditorTextButton(title: "새 맵 만들기", icon: "plus", action: onNew)
                .frame(maxWidth: 260)
                .padding(.top, 8)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 목록

    /// 내용 최대 폭 — 아이패드는 격자라 넓게 (아이폰·맥은 기존 680 그대로)
    private var contentMaxWidth: CGFloat { isPadIdiom ? 1100 : 680 }

    private var list: some View {
        ScrollView {
            Group {
                if isPadIdiom {
                    // 아이패드 — 큰 썸네일 카드 격자 (예전엔 맥과 같은 한 줄 목록이라 양옆이 넓게 비었음)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        ForEach(vm.rows) { row in
                            padCard(row)
                        }
                    }
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.rows) { row in
                            rowView(row)
                        }
                    }
                }
            }
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func rowView(_ row: CustomMapListViewModel.Row) -> some View {
        HStack(spacing: 12) {
            Button {
                guard row.isPlayable else { return }
                SoundService.shared.play(.buttonTap)
                onPlay(row.id)
            } label: {
                HStack(spacing: 12) {
                    CustomMapThumbnail(map: row.map)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("\(row.sizeText) · \(row.elementsText)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(row.starText)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(row.name) 플레이")

            rowMenu(row)
        }
        .padding(12)
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 아이패드 격자 카드 — 큰 썸네일 + 이름·정보, 오른쪽 아래 메뉴 (누르면 플레이 — 목록 줄과 같은 동작)
    private func padCard(_ row: CustomMapListViewModel.Row) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                guard row.isPlayable else { return }
                SoundService.shared.play(.buttonTap)
                onPlay(row.id)
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    CustomMapThumbnail(map: row.map)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("\(row.sizeText) · \(row.elementsText)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(row.starText)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 40)  // 오른쪽 아래 메뉴 버튼과 글자가 겹치지 않게
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(row.name) 플레이")
        }
        .overlay(alignment: .bottomTrailing) { rowMenu(row) }
        .padding(14)
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 플레이·수정·삭제 메뉴 (목록 줄·격자 카드 공용)
    private func rowMenu(_ row: CustomMapListViewModel.Row) -> some View {
        Menu {
            if row.isPlayable {
                Button { onPlay(row.id) } label: { Label("플레이", systemImage: "play.fill") }
                Button { onEdit(row.id) } label: { Label("수정", systemImage: "pencil") }
            }
            Button(role: .destructive) { deleteTarget = row } label: { Label("삭제", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("\(row.name) 메뉴")
    }

    // MARK: - 삭제 확인

    private func deleteConfirm(_ row: CustomMapListViewModel.Row) -> some View {
        ConfirmCardOverlay(
            icon: "trash.fill",
            title: "맵을 삭제할까요?",
            message: "'\(row.name)' 맵이 사라지고 되돌릴 수 없어요.",
            accentColor: .failureRed,
            primaryTitle: "삭제",
            onPrimary: {
                vm.delete(id: row.id)
                deleteTarget = nil
            },
            onDismiss: { deleteTarget = nil },
            showsCancel: true
        )
    }
}

// MARK: - CustomMapPlayView
/// 저장된 맵을 플레이하는 화면 — 번호로 맵을 찾아 게임 화면(StageView)에 넣음
/// 맵이 없거나 손상됐으면 안내와 돌아가기 버튼을 보여 줌
struct CustomMapPlayView: View {

    private let id: UUID
    private let service: CustomMapService?
    private let showsOwnBackButton: Bool
    private let onExit: () -> Void

    /// 플레이할 맵 — 화면이 처음 나타날 때 한 번만 디코딩 (init에서 하면 부모가 다시 그릴 때마다 디코딩함)
    private enum Content {
        case loading         // 아직 읽지 않음
        case ready(Stage)    // 플레이 가능
        case missing         // 지워졌거나 손상된 맵
    }
    @State private var content: Content = .loading

    /// - Parameter service: 맵 저장소 — 테스트·프리뷰는 격리된 저장소를 주입
    init(id: UUID, service: CustomMapService? = nil, showsOwnBackButton: Bool = true, onExit: @escaping () -> Void) {
        self.id = id
        self.service = service
        self.showsOwnBackButton = showsOwnBackButton
        self.onExit = onExit
    }

    var body: some View {
        Group {
            switch content {
            case .loading:
                Color.appBackground.ignoresSafeArea()
                    .hideNavigationBar()
            case .ready(let stage):
                StageView(stage: stage, navPath: .constant(NavigationPath()),
                          showsOwnBackButton: showsOwnBackButton, onExit: onExit)
                    .id(stage.id)
            case .missing:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.45))
                    Text("맵을 열 수 없어요")
                        .font(.system(size: 18, weight: .bold))
                    EditorTextButton(title: "돌아가기", action: onExit)
                        .frame(maxWidth: 200)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground.ignoresSafeArea())
                .hideNavigationBar()
            }
        }
        .onAppear {
            guard case .loading = content else { return }
            if let stage = (service ?? .shared).map(withID: id)?.stage {
                content = .ready(stage)
            } else {
                content = .missing
            }
        }
    }
}
