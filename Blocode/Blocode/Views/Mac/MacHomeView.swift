//
//  MacHomeView.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

// 맥 전용 홈 — 한 화면에 다 보이는 대시보드 (아이폰은 ContentView, 아이패드는 PadHomeView)
// 버튼·카드·색은 아이폰·아이패드와 같은 공용 부품을 그대로 씀 — 배치만 맥에 맞춤
#if os(macOS)
import SwiftUI

// MARK: - MacHomeView
/// 위: 오늘의 한 줄 / 가운데: 이어서 할 스테이지(왼쪽 큰 카드) + 오늘의·랜덤 퍼즐(오른쪽) / 아래: 15장 진행 격자
/// (예전엔 버튼 두 개가 화면 맨 아래에 떨어져 있고 가운데가 비어 있었음 — 별·연속 기록은 사이드바 아래에 있어서 여기선 뺌)
struct MacHomeView: View {

    let vm: HomeViewModel
    let chapterSelectVM: ChapterSelectViewModel
    @Binding var lockInfo: LockInfo?
    /// 게임·퍼즐 화면 열기 — 셸의 스택에 올림
    let onOpen: (AppRoute) -> Void
    /// 챕터 화면 열기 — nil이면 챕터 지도
    let onShowChapter: (Int?) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                quoteSection

                HStack(alignment: .top, spacing: 16) {
                    nextStageCard
                    puzzleColumn
                        .frame(width: 300)
                }

                chapterSection
            }
            .padding(36)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 오늘의 한 줄

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘의 한 줄").font(.system(size: 13)).foregroundStyle(.secondary)
            Text(vm.dailyQuote.joined)  // 매일 바뀌는 문구
                .font(.system(size: 32, weight: .bold, design: .serif))
                .italic()
            Text(vm.dynamicSubtitle)
                .font(.system(size: 14)).foregroundStyle(.secondary)
        }
    }

    // MARK: - 이어서 할 스테이지

    /// 미리보기 맵(왼쪽) + 스테이지 정보와 버튼(오른쪽) — 모두 깼으면 완료 카드
    private var nextStageCard: some View {
        Group {
            if let stage = vm.nextStageDetail {
                HStack(alignment: .top, spacing: 20) {
                    // 실제 게임과 같은 SpriteKit 미리보기 — 스테이지가 바뀌면 새로 그림
                    StagePreviewMapView(stage: stage)
                        .id(stage.id)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 210)
                    VStack(alignment: .leading, spacing: 14) {
                        stageInfo(stage)
                        Spacer(minLength: 0)
                        continueButtons
                    }
                }
            } else {
                allClearedContent
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    /// 챕터 배지 + "NEXT STAGE · 챕터 n 이름" + 스테이지 이름 + 별 3개 기준
    private func stageInfo(_ stage: Stage) -> some View {
        let chapter = ChapterCatalog.chapter(stage.chapter)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(chapter?.color ?? .accentColor)
                    Text("\(stage.chapter)")
                        .font(.system(size: 17, weight: .bold, design: .serif)).italic()
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(vm.isFirstTime ? "FIRST STAGE" : "NEXT STAGE")
                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary).tracking(1.2)
                    Text("챕터 \(stage.chapter) · \(chapter?.title ?? "")")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("STAGE \(stage.chapter)-\(stage.stageNumber)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                Text(stage.name)
                    .font(.system(size: 24, weight: .bold))
            }
            Label("\(stage.starThresholds.threeStar)블럭 이하로 풀면 별 3개", systemImage: "star.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    /// 이어서 하기 + 챕터 둘러보기 (아이폰·아이패드 홈과 같은 3D 버튼)
    private var continueButtons: some View {
        VStack(spacing: 10) {
            HomeContinueButton(next: vm.nextStage, isFirstTime: vm.isFirstTime) {
                if let next = vm.nextStage {
                    onOpen(.stage(chapter: next.chapter, number: next.stage))
                } else {
                    onShowChapter(nil)
                }
            }
            HomeBrowseButton { onShowChapter(nil) }
        }
    }

    /// 모든 스테이지를 깼을 때 — 축하 문구와 챕터 둘러보기
    private var allClearedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.statSealMint)
            VStack(alignment: .leading, spacing: 6) {
                Text("모든 챕터를 완료했어요")
                    .font(.system(size: 22, weight: .bold))
                Text("오늘의 퍼즐과 랜덤 퍼즐로 계속 실력을 다듬어 보세요.\n별을 더 적은 블럭으로 다시 따 보는 것도 좋아요.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            // 이어서 할 스테이지가 없으니 챕터 둘러보기만 (퍼즐은 오른쪽 카드에 있음)
            HomeBrowseButton { onShowChapter(nil) }
        }
    }

    // MARK: - 오늘의·랜덤 퍼즐

    /// 두 퍼즐 카드를 위아래로 — 오른쪽에 "도전 ›"·"시작 ›" 표시
    private var puzzleColumn: some View {
        DailyPuzzleCard(info: vm.dailyPuzzle,
                        isLocked: !vm.isUnlocked(.dailyPuzzle),
                        showsActionHint: true,
                        onDaily: { openIfUnlocked(.dailyPuzzle, .dailyPuzzle(vm.dailyPuzzle.key)) },
                        onRandom: { openIfUnlocked(.dailyPuzzle, .newRandomPuzzle()) })
    }

    /// 열려 있으면 해당 화면으로 이동, 잠겨 있으면 해금 조건 팝업 (잠금 사운드 포함)
    private func openIfUnlocked(_ feature: UnlockableFeature, _ route: AppRoute) {
        if vm.isUnlocked(feature) {
            onOpen(route)
        } else {
            $lockInfo.present(vm.lockHint(for: feature))
        }
    }

    // MARK: - 챕터 진행

    /// 15장을 한눈에 — 누르면 그 챕터 화면으로, 잠긴 장은 해금 조건 팝업
    private var chapterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("챕터")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button {
                    SoundService.shared.play(.buttonTap)
                    onShowChapter(nil)
                } label: {
                    HStack(spacing: 2) {
                        Text("지도로 보기")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(chapterSelectVM.chapters) { chapter in
                    chapterTile(chapter)
                }
            }
        }
    }

    /// 챕터 한 칸 — 번호 배지(잠기면 자물쇠) + 이름 + 깬 스테이지 수 + 진행 막대
    private func chapterTile(_ chapter: ChapterInfo) -> some View {
        let unlocked = chapterSelectVM.isUnlocked(chapter)
        let cleared = chapterSelectVM.clearedStageCount(chapter)
        return Button {
            if unlocked {
                SoundService.shared.play(.buttonTap)
                onShowChapter(chapter.number)
            } else {
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(message: chapterSelectVM.lockMessage(for: chapter), accentColor: chapter.color)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(unlocked ? chapter.color : Color.lockedBackground)
                        if unlocked {
                            Text("\(chapter.number)")
                                .font(.system(size: 15, weight: .bold, design: .serif)).italic()
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(chapter.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(unlocked ? .primary : .secondary)
                        Text("\(cleared)/\(chapter.stageCount) 스테이지")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                // 깬 스테이지 비율 막대 — 챕터 색
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.statCardBackground)
                        Capsule()
                            .fill(unlocked ? chapter.color : Color.clear)
                            .frame(width: geo.size.width * CGFloat(cleared) / CGFloat(max(chapter.stageCount, 1)))
                    }
                }
                .frame(height: 5)
            }
            .padding(12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("homeChapter-\(chapter.number)")
    }
}
#endif
