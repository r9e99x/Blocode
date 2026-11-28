//
//  PhoneHomeView.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

// 아이폰 전용 홈 — 탭 막대 셸(ContentView)의 홈 탭 (아이패드는 PadHomeView, 맥은 MacHomeView)
// 버튼·카드·색은 아이패드·맥과 같은 공용 부품을 그대로 씀 — 배치만 아이폰에 맞춤
#if os(iOS)
import SwiftUI

// MARK: - PhoneHomeView
/// 세로: 로고·설정 → 오늘의 한 줄 → "이어서 하기" 카드(맵 미리보기 포함) → 오늘의·랜덤 퍼즐 반 칸씩 → 별·연속·챕터 한 줄 요약
/// 가로: 왼쪽 로고·한 줄·요약 / 오른쪽 이어서 하기 카드·퍼즐
/// (예전엔 통계 카드 3장 아래 버튼 3개가 화면 맨 아래에 고정돼 있었음 — 챕터·내 맵·개념 카드는 이제 아래 탭으로 감)
struct PhoneHomeView: View {

    let vm: HomeViewModel
    @Binding var lockInfo: LockInfo?
    /// 게임·퍼즐 화면 열기 — 홈 탭 스택에 올림
    let open: (AppRoute) -> Void
    /// 챕터 탭으로 (모두 깼을 때 "챕터 둘러보기")
    let showChapters: () -> Void

    /// 설정 화면 표시 여부 — 오른쪽 위 톱니
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                if geo.size.width >= LayoutBreakpoint.wide {
                    wideContent
                } else {
                    compactContent
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .hideNavigationBar()
        // 설정 화면 — 전체 화면 모달 (예전과 같음)
        .fullScreenCoverCompat(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - 세로

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            quoteSection
                .padding(.top, 24)
            continueCard
                .padding(.top, 22)
            puzzleRow
                .padding(.top, 12)
            statsLine
                .padding(.top, 14)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    // MARK: - 가로

    /// 가로는 세로가 짧아 두 칸으로 — 왼쪽 로고·한 줄·요약 / 오른쪽 카드·퍼즐
    private var wideContent: some View {
        HStack(alignment: .top, spacing: 36) {
            VStack(alignment: .leading, spacing: 0) {
                header
                quoteSection
                    .padding(.top, 24)
                statsLine
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                continueCard
                puzzleRow
            }
            .frame(width: 400)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .frame(maxWidth: 1120)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 머리글

    /// 로고 + 앱 이름 / 오른쪽 설정 버튼 (개념 카드 버튼은 아래 탭으로 옮김)
    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                // 앱 로고와 같은 3D 미니 아이콘 (온보딩과 공용 부품)
                MiniLogoIcon(size: 36, topDepth: 1.0, bottomDepth: 2.0, cornerRadius: 10, arrowSize: 14)
                Text("Blocode")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Button {
                SoundService.shared.play(.buttonTap)
                showSettings = true
            } label: {
                CardIconLabel(icon: "gearshape", fontSize: 14, background: .cardBackground, shadowOpacity: 0.08, shadowY: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("설정")
        }
    }

    // MARK: - 오늘의 한 줄

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘의 한 줄")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            // 매일 바뀌는 문구 — Georgia Italic (한국어는 기울임 변환으로 이탤릭 효과), 길면 한 줄 안에서 글자를 줄임
            VStack(alignment: .leading, spacing: 0) {
                quoteLine(vm.dailyQuote.first)
                quoteLine(vm.dailyQuote.second)
            }
            Text(vm.dynamicSubtitle)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    private func quoteLine(_ text: String) -> some View {
        Text(text)
            .font(.custom("Georgia-Italic", size: 34))
            .foregroundStyle(.primary)
            .lineLimit(1).minimumScaleFactor(0.6)
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.12, d: 1, tx: 0, ty: 0))
    }

    // MARK: - 이어서 하기 카드

    /// 다음 스테이지 미리보기 맵(왼쪽) + 정보(오른쪽) + 아래 3D 버튼 — 모두 깼으면 완료 카드
    private var continueCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let stage = vm.nextStageDetail {
                HStack(alignment: .center, spacing: 14) {
                    // 실제 게임과 같은 SpriteKit 미리보기 — 스테이지가 바뀌면 새로 그림
                    StagePreviewMapView(stage: stage)
                        .id(stage.id)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 112)
                    stageInfo(stage)
                    Spacer(minLength: 0)
                }
                HomeContinueButton(next: vm.nextStage, isFirstTime: vm.isFirstTime) {
                    if let next = vm.nextStage {
                        open(.stage(chapter: next.chapter, number: next.stage))
                    } else {
                        showChapters()
                    }
                }
            } else {
                allCleared
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    /// "NEXT STAGE" + "챕터 n · 이름" + 스테이지 이름 + 별 3개 기준
    private func stageInfo(_ stage: Stage) -> some View {
        let chapter = ChapterCatalog.chapter(stage.chapter)
        return VStack(alignment: .leading, spacing: 5) {
            Text(vm.isFirstTime ? "FIRST STAGE" : "NEXT STAGE")
                .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary).tracking(1.2)
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(chapter?.color ?? .accentColor)
                    .frame(width: 10, height: 10)
                Text("챕터 \(stage.chapter) · \(chapter?.title ?? "")")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
            Text(stage.name)
                .font(.system(size: 20, weight: .bold))
                .lineLimit(1).minimumScaleFactor(0.8)
            Label("\(stage.starThresholds.threeStar)블럭 이하면 별 3개", systemImage: "star.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    /// 모든 스테이지를 깼을 때 — 축하 문구 + 챕터 둘러보기
    private var allCleared: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.statSealMint)
                Text("모든 챕터를 완료했어요")
                    .font(.system(size: 18, weight: .bold))
            }
            Text("오늘의 퍼즐과 랜덤 퍼즐로 실력을 다듬어 보세요.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            HomeBrowseButton { showChapters() }
        }
    }

    // MARK: - 퍼즐

    /// 오늘의 퍼즐·랜덤 퍼즐을 반 칸씩 한 줄에 — 오른쪽에 "도전 ›"·"시작 ›"
    private var puzzleRow: some View {
        DailyPuzzleCard(info: vm.dailyPuzzle,
                        isLocked: !vm.isUnlocked(.dailyPuzzle),
                        isCompact: true,
                        showsActionHint: true,
                        onDaily: { openIfUnlocked(.dailyPuzzle, .dailyPuzzle(vm.dailyPuzzle.key)) },
                        onRandom: { openIfUnlocked(.dailyPuzzle, .newRandomPuzzle()) })
    }

    /// 열려 있으면 해당 화면으로 이동, 잠겨 있으면 해금 조건 팝업 (잠금 사운드 포함)
    private func openIfUnlocked(_ feature: UnlockableFeature, _ route: AppRoute) {
        if vm.isUnlocked(feature) {
            open(route)
        } else {
            $lockInfo.present(vm.lockHint(for: feature))
        }
    }

    // MARK: - 요약 한 줄

    /// 별·연속·챕터 완료를 한 줄로 (예전 통계 카드 3장의 내용)
    private var statsLine: some View {
        HStack(spacing: 14) {
            statItem(icon: "star.fill", color: .starGold, text: "\(vm.earnedStars)/\(vm.totalPossibleStars)")
            statItem(icon: "flame.fill", color: .statFlameOrange, text: "\(vm.streak)일째")
            statItem(icon: "checkmark.seal.fill", color: .statSealMint, text: "\(vm.completedChapters)/\(vm.chapterCount)장")
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.statCardBackground)
        .clipShape(Capsule())
    }

    private func statItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
            Text(text).foregroundStyle(.primary)
        }
    }
}
#endif
