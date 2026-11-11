//
//  LearningLibraryView.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - LearningLibraryView
/// 학습 보관함 — 블럭 개념 / 코딩 기초 / CS 기초 카드를 탭으로 나눠 보여 주는 화면
/// 아이폰은 뒤로가기가 있는 전체 화면, 아이패드·맥은 사이드바 옆 콘텐츠 패널로 쓰임(onBack이 nil)
struct LearningLibraryView: View {

    /// 뒤로가기 — nil이면 뒤로가기 버튼을 그리지 않음 (사이드바 셸에 들어갈 때)
    var onBack: (() -> Void)? = nil

    @ObservedObject private var learning = LearningService.shared
    @State private var category: LearningCategory = .block
    @State private var openedCard: LearningCard?
    @State private var lockInfo: LockInfo?

    private var cards: [LearningCard] { LearningCatalog.cards(in: category) }

    var body: some View {
        VStack(spacing: 0) {
            header
            categoryTabs
            if cards.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .lockInfoPopup($lockInfo)
        .sheet(item: $openedCard) { LearningCardSheet(card: $0) }
        .hideNavigationBar()
        // 이미 진행한 사용자의 수집을 채움 (화면을 열 때마다 한 번 — 가벼운 계산)
        .onAppear { learning.syncFromProgress(.shared) }
    }

    // MARK: - 머리글

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button {
                    SoundService.shared.play(.buttonTap)
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("개념 카드 모음")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("library")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    // MARK: - 탭

    private var categoryTabs: some View {
        HStack(spacing: 8) {
            ForEach(LearningCategory.allCases) { item in
                let selected = item == category
                let progress = learning.progress(in: item)
                Button {
                    SoundService.shared.play(.buttonTap)
                    withAnimation(.easeInOut(duration: 0.15)) { category = item }
                } label: {
                    VStack(spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(progress.unlocked)/\(progress.total)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .opacity(0.7)
                    }
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(selected ? Color.slateButtonFace : Color.statCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - 목록

    private var list: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(cards) { card in
                    cardRow(card)
                }
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func cardRow(_ card: LearningCard) -> some View {
        let unlocked = learning.isUnlocked(card)
        return Button {
            if unlocked {
                SoundService.shared.play(.buttonTap)
                openedCard = card
            } else {
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) { lockInfo = lockInfo(for: card) }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: unlocked ? "book.closed.fill" : "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(unlocked ? Color.starGold : Color.secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(unlocked ? card.title : "???")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(unlocked ? card.summary : unlockHint(for: card))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if unlocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.statCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .opacity(unlocked ? 1 : 0.55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unlocked ? "\(card.title), \(card.summary)" : "잠긴 카드, \(unlockHint(for: card))")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("카드를 준비하고 있어요")
                .font(.system(size: 15, weight: .semibold))
            Text("조금만 기다려 주세요.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 잠금 안내

    /// 카드가 열리는 조건 한 줄 — 블럭이 처음 나오는 챕터를 알려 줌
    private func unlockHint(for card: LearningCard) -> String {
        guard case .block(let block) = card.unlock, let first = FirstAppearance.stage(of: block),
              let chapter = ChapterCatalog.chapter(first.chapter) else { return "아직 열리지 않았어요" }
        return "챕터 \(chapter.number) \"\(chapter.title)\"에서 처음 만나면 열려요"
    }

    private func lockInfo(for card: LearningCard) -> LockInfo {
        var accent = Color.gray
        if case .block(let block) = card.unlock, let first = FirstAppearance.stage(of: block),
           let chapter = ChapterCatalog.chapter(first.chapter) {
            accent = chapter.color
        }
        return LockInfo(message: unlockHint(for: card).replacingOccurrences(of: "에서 처음 만나면 열려요", with: "에서\n처음 만나면 열려요"),
                        accentColor: accent)
    }
}

// MARK: - LearningCardSheet
/// 카드 한 장의 자세한 내용 — 요약, 설명, 팁, 코드 예시(언어 선택)
struct LearningCardSheet: View {

    let card: LearningCard
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(card.summary)
                        .font(.system(size: 17, weight: .bold))
                    Text(card.body)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundStyle(.primary.opacity(0.85))

                    if let tip = card.tip {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color.starGold)
                            Text(tip)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.statCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if card.example != nil { exampleSection }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 460)
        #endif
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(card.category.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(card.title)
                    .font(.system(size: 22, weight: .bold))
            }
            Spacer()
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
        .padding(.bottom, 12)
    }

    /// 코드 예시 — 언어를 바꿔 가며 볼 수 있음 (고른 언어는 "코드로 보기"와 공유)
    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("코드로 보면")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            CodeLanguageChips(selection: $settings.codeLanguage)
                .padding(.horizontal, -20)  // 칩 줄은 화면 가장자리까지 스크롤되게
            ScrollView(.horizontal, showsIndicators: false) {
                Text(card.exampleCode(in: settings.codeLanguage) ?? "")
                    .font(.system(size: 13, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    LearningLibraryView()
}
