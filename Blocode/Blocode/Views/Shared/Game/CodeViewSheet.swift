//
//  CodeViewSheet.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - CodeViewSheet
/// "코드로 보기" — 지금 쌓은 블럭을 선택한 언어의 텍스트 코드로 보여 주는 시트
/// 언어는 위쪽 칩으로 바꾸고, 마지막에 고른 언어를 기억함 (SettingsService.codeLanguage)
struct CodeViewSheet: View {

    let blocks: [Block]
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss

    /// 복사 직후 버튼 문구를 잠깐 바꾸기 위한 표시
    @State private var copied = false

    private var code: String { CodeRenderer.render(blocks, language: settings.codeLanguage) }

    var body: some View {
        VStack(spacing: 0) {
            header
            languagePicker
                .padding(.top, 4)

            // 긴 줄(예: Java의 main 선언)이 줄바꿈되면 들여쓰기가 흐트러지므로 가로 스크롤로 보여 줌
            // (두 방향을 한 ScrollView로 합치면 짧은 코드가 세로 가운데로 가서, 세로 안에 가로를 겹쳐 맨 위부터 보이게 함)
            ScrollView(.vertical) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(16)
                }
            }
            .background(Color.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text("블럭을 프로그램으로 옮기면 이렇게 보여요. move_forward() 같은 명령은 캐릭터를 움직이고, step1… 같은 보조 함수는 함수 블럭이에요.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .background(Color.appBackground.ignoresSafeArea())
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 420)
        #endif
        .presentationDetents([.medium, .large])  // iOS: 반 높이로 열리고 끌어 올리면 전체
    }

    // MARK: - 헤더

    private var header: some View {
        HStack {
            Text("코드로 보기")
                .font(.system(size: 18, weight: .bold))
            Spacer()
            Button {
                copyToClipboard(code)
                SoundService.shared.play(.buttonTap)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Label(copied ? "복사됨" : "복사", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.trailing, 10)

            Button {
                SoundService.shared.play(.buttonTap)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color.closeButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - 언어 선택

    private var languagePicker: some View {
        CodeLanguageChips(selection: $settings.codeLanguage)
    }

    /// 클립보드에 복사 (iOS·맥 공용)
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

#Preview {
    CodeViewSheet(blocks: [
        Block(type: .repeatBlock, repeatCount: 3, children: [Block(type: .moveForward), Block(type: .turnRight)]),
        Block(type: .ifBlock, children: [Block(type: .turnLeft)], ifCondition: .pathBlocked)
    ])
}

// MARK: - CodeLanguageChips
/// 코드 언어를 고르는 칩 한 줄 — "코드로 보기"와 학습 카드 상세가 함께 씀 (고른 언어는 설정에 저장됨)
struct CodeLanguageChips: View {

    @Binding var selection: CodeLanguage

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CodeLanguage.allCases) { language in
                    let selected = language == selection
                    Button {
                        SoundService.shared.play(.buttonTap)
                        selection = language
                    } label: {
                        Text(language.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected ? Color.slateButtonFace : Color.statCardBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
