//
//  MapEditorView.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import SwiftUI

// MARK: - MapEditorView
/// 맵 에디터 화면 — 격자, 도구, 안내, 확인·저장을 조립
/// 아이폰 세로(와 아이패드 세로)는 위에서 아래로 쌓고, 가로로 넓은 화면은 왼쪽 패널과 오른쪽 격자로 나눔
/// 상태와 규칙은 모두 MapEditorViewModel에 있고 이 화면은 그리기만 함
struct MapEditorView: View {

    @StateObject private var editor: MapEditorViewModel

    private let service: CustomMapService
    private let onClose: () -> Void
    private let onSaved: ((CustomMap) -> Void)?
    /// 자체 뒤로가기 버튼 표시 여부 (맥은 툴바 버튼을 쓸 수 있도록 끌 수 있음)
    private let showsOwnBackButton: Bool

    @State private var showSettings = false
    @State private var showLeaveConfirm = false
    /// 테스트 플레이 중인 스테이지 — 값이 있으면 게임 화면을 전체 화면으로 띄움
    @State private var testStage: Stage?
    /// 저장 결과 같은 한 줄 알림 — 맵을 고치거나 이름을 바꾸면 사라짐
    @State private var notice: String?

    /// - Parameter editing: 이미 저장된 맵을 고칠 때 전달 (손상된 맵이면 새 맵으로 열림)
    @MainActor
    init(editing: CustomMap? = nil, service: CustomMapService? = nil,
         showsOwnBackButton: Bool = true,
         onSaved: ((CustomMap) -> Void)? = nil,
         onClose: @escaping () -> Void) {
        let model = editing.flatMap(MapEditorViewModel.init(editing:)) ?? MapEditorViewModel()
        _editor = StateObject(wrappedValue: model)
        self.service = service ?? .shared
        self.showsOwnBackButton = showsOwnBackButton
        self.onSaved = onSaved
        self.onClose = onClose
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            Group {
                if geo.size.width > geo.size.height && geo.size.width >= LayoutBreakpoint.wide {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .padding(16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .overlay {
            if showLeaveConfirm { leaveConfirm }
        }
        .sheet(isPresented: $showSettings) { settingsSheet }
        .fullScreenCoverCompat(isPresented: Binding(get: { testStage != nil },
                                                    set: { if !$0 { testStage = nil } })) {
            testPlayScreen
        }
        .onChange(of: editor.name) { _, name in
            if name.count > CustomMapService.maxNameLength {
                editor.name = String(name.prefix(CustomMapService.maxNameLength))
            }
            notice = nil
        }
        .onChange(of: editor.isDirty) { _, isDirty in
            if isDirty { notice = nil }
        }
        .hideNavigationBar()
    }

    // MARK: - 레이아웃

    /// 위에서 아래로: 상단 바 → 격자 → 안내 → 도구 → 버튼
    private var compactLayout: some View {
        VStack(spacing: 10) {
            topBar
            MapEditorGridView(editor: editor)
            hintLine
            MapEditorToolPicker(editor: editor)
            actionBar(showsSettingsButton: true)
        }
        .frame(maxWidth: 640)          // 아이패드 세로에서 버튼이 너무 퍼지지 않게
        .frame(maxWidth: .infinity)
    }

    /// 왼쪽: 상단 바·도구·설정·안내·버튼 / 오른쪽: 격자
    private var wideLayout: some View {
        HStack(spacing: 16) {
            VStack(spacing: 12) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        MapEditorToolPicker(editor: editor, isGrid: true)
                        hintLine
                        MapEditorSettingsView(editor: editor)
                    }
                }
                actionBar(showsSettingsButton: false)
            }
            .frame(width: 320)

            MapEditorGridView(editor: editor)
        }
    }

    // MARK: - 상단 바

    private var topBar: some View {
        HStack(spacing: 10) {
            if showsOwnBackButton {
                Button {
                    SoundService.shared.play(.buttonTap)
                    requestClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color.panelBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
            }

            TextField("맵 이름", text: $editor.name)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .bold))
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color.statCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                SoundService.shared.play(.buttonTap)
                save()
            } label: {
                Text("저장")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(Color.slateButtonFace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 안내 줄

    /// 거부 안내 > 짝 맺기 안내 > 저장 알림 > 확인 결과 > 도구 사용법 순서로 한 가지를 보여 줌
    private var hintText: (text: String, isProblem: Bool) {
        if let message = editor.message { return (message, true) }
        if let pending = editor.pending {
            switch pending {
            case .switchCell: return ("스위치를 놓았어요. 열릴 문을 놓을 칸을 누르세요. 같은 칸을 다시 누르면 취소돼요.", false)
            case .portalEnd: return ("포탈 한쪽을 놓았어요. 짝이 될 칸을 누르세요. 같은 칸을 다시 누르면 취소돼요.", false)
            }
        }
        if let notice { return (notice, false) }
        if let validation = editor.validation {
            if validation.isValid, let shortest = validation.shortestSolution?.count, let thresholds = editor.thresholds {
                return ("확인 완료 · 가장 짧은 풀이는 \(shortest)블럭이고, 별 3개는 \(thresholds.threeStar)블럭 이하예요.", false)
            }
            return (validation.issues.joined(separator: "\n"), true)
        }
        return (editor.tool.hint, false)
    }

    private var hintLine: some View {
        let hint = hintText
        return Text(hint.text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(hint.isProblem ? Color.failureRed : Color.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.statCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 하단 버튼

    private func actionBar(showsSettingsButton: Bool) -> some View {
        HStack(spacing: 8) {
            EditorIconButton(icon: "arrow.uturn.backward", label: "되돌리기", isEnabled: editor.canUndo) {
                editor.undo()
            }
            EditorIconButton(icon: "arrow.uturn.forward", label: "다시 하기", isEnabled: editor.canRedo) {
                editor.redo()
            }
            if showsSettingsButton {
                EditorIconButton(icon: "slider.horizontal.3", label: "맵 설정") { showSettings = true }
            }
            EditorTextButton(title: "확인", icon: "checkmark") {
                editor.validate()
            }
            EditorTextButton(title: "테스트 플레이", icon: "play.fill", face: .runButtonActiveMint) {
                startTestPlay()
            }
        }
    }

    // MARK: - 설정 시트·나가기 확인

    private var settingsSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("맵 설정").font(.system(size: 17, weight: .bold))
                Spacer()
                Button("완료") { showSettings = false }
                    .font(.system(size: 15, weight: .semibold))
                    .buttonStyle(.plain)
            }
            .padding(20)
            ScrollView {
                MapEditorSettingsView(editor: editor)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .preferredColorScheme(SettingsService.shared.theme.colorScheme)
    }

    /// 만든 맵을 직접 플레이 — 클리어하면 그 블럭 수로 별 3개 기준이 내려감
    @ViewBuilder
    private var testPlayScreen: some View {
        if let stage = testStage {
            StageView(stage: stage, navPath: .constant(NavigationPath()),
                      onExit: { testStage = nil },
                      onCleared: { editor.recordTestClear(blockCount: $0) })
                .id(stage.id)
                .preferredColorScheme(SettingsService.shared.theme.colorScheme)
                #if os(macOS)
                .frame(minWidth: 960, minHeight: 680)  // 맥 시트는 내용 크기를 따르므로 게임 화면이 충분히 크도록
                #endif
        }
    }

    private var leaveConfirm: some View {
        ConfirmCardOverlay(
            icon: "exclamationmark.triangle.fill",
            title: "저장하지 않고 나갈까요?",
            message: "고친 내용이 저장되지 않아요.",
            accentColor: .switchOrange,
            primaryTitle: "나가기",
            onPrimary: {
                showLeaveConfirm = false
                onClose()
            },
            onDismiss: { showLeaveConfirm = false },
            showsCancel: true
        )
    }

    // MARK: - 동작

    private func requestClose() {
        if editor.isDirty {
            showLeaveConfirm = true
        } else {
            onClose()
        }
    }

    private func save() {
        do {
            let saved = try editor.save(to: service)
            notice = "저장했어요."
            onSaved?(saved)
        } catch CustomMapService.SaveError.invalidMap {
            // 문제 목록은 확인 결과로 안내 줄에 보임
            notice = nil
        } catch {
            notice = error.localizedDescription
        }
    }

    /// 확인을 통과한 맵만 테스트 플레이 — 통과하지 못하면 문제 목록이 안내 줄에 보임
    private func startTestPlay() {
        let result = editor.validation ?? editor.validate()
        guard result.isValid, let stage = editor.previewStage else { return }
        testStage = stage
    }
}

#Preview("세로") {
    MapEditorView(onClose: {})
}

#if !os(macOS)
#Preview("가로", traits: .landscapeLeft) {
    MapEditorView(onClose: {})
}
#endif
