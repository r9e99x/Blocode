//
//  PadHomeView.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

// 아이패드 전용 홈 — 아이폰 홈(ContentView)·맥 홈(SidebarShell)과 같은 부품을 쓰고 배치만 아이패드에 맞춤
#if os(iOS)
import SwiftUI

// MARK: - PadHomeView
/// 문구 → 통계 → "다음 스테이지" 큰 카드(미리보기 맵 + 이어서 하기) → 퍼즐 → 챕터 진행(격자)
/// 가로는 세로 공간이 모자라 문구와 통계를 한 줄에 나란히 둠
/// 예전엔 맥과 같은 배치라 세로에서 위쪽 카드와 맨 아래 버튼 사이가 화면 절반 넘게 비었음
struct PadHomeView: View {

    let vm: HomeViewModel
    let chapterSelectVM: ChapterSelectViewModel
    @Binding var lockInfo: LockInfo?
    /// 홈 탭 스택에 화면 올리기 (스테이지·퍼즐)
    let open: (AppRoute) -> Void
    /// 챕터 탭으로 이동 — 번호가 있으면 그 챕터 화면, nil이면 챕터 지도
    let showChapters: (Int?) -> Void

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    if isLandscape {
                        HStack(alignment: .bottom, spacing: 32) {
                            quoteSection
                            Spacer(minLength: 0)
                            HomeStatsRow(vm: vm, spacing: 14)
                                .frame(maxWidth: 520)
                        }
                    } else {
                        quoteSection
                        HomeStatsRow(vm: vm, spacing: 14)
                    }
                    nextStageCard
                    dailyCard
                    chapterSection
                }
                .padding(.horizontal, 48)
                .padding(.top, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: 1180)  // 아주 큰 창에서도 내용이 너무 퍼지지 않게
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - 오늘의 한 줄

    /// 아이폰 홈과 같은 문구 모양 — 아이패드는 글자를 조금 키움
    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘의 한 줄")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            VStack(alignment: .leading, spacing: 0) {
                quoteLine(vm.dailyQuote.first)
                quoteLine(vm.dailyQuote.second)
            }
            Text(vm.dynamicSubtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    /// Georgia 기울임 한 줄 (한국어는 시스템 글꼴로 대체되어 기울임 변환으로 같은 느낌을 냄 — 아이폰 홈과 같은 방식)
    private func quoteLine(_ text: String) -> some View {
        Text(text)
            .font(.custom("Georgia-Italic", size: 46))
            .lineLimit(1).minimumScaleFactor(0.6)
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.12, d: 1, tx: 0, ty: 0))
    }

    // MARK: - 퍼즐 카드

    /// 오늘의 퍼즐·랜덤 퍼즐 — 아이패드는 폭이 넓어 두 카드를 한 줄에 나란히
    private var dailyCard: some View {
        DailyPuzzleCard(info: vm.dailyPuzzle,
                        isLocked: !vm.isUnlocked(.dailyPuzzle),
                        isCompact: true,
                        showsActionHint: true,  // 아이폰 홈처럼 오른쪽에 "도전 ›"·"시작 ›"
                        onDaily: { openIfUnlocked(.dailyPuzzle, .dailyPuzzle(vm.dailyPuzzle.key)) },
                        onRandom: { openIfUnlocked(.dailyPuzzle, AppRoute.newRandomPuzzle()) })
    }

    /// 열려 있으면 화면 이동, 잠겨 있으면 해금 조건 팝업 (잠금 사운드 포함)
    private func openIfUnlocked(_ feature: UnlockableFeature, _ route: AppRoute) {
        if vm.isUnlocked(feature) {
            open(route)
        } else {
            $lockInfo.present(vm.lockHint(for: feature))
        }
    }

    // MARK: - 다음 스테이지 카드

    /// 이어서 할 스테이지 카드 — 맵(왼쪽)·설명과 버튼(오른쪽), 모두 완료면 완료 카드
    private var nextStageCard: some View {
        Group {
            if let stage = vm.nextStageDetail {
                HStack(alignment: .center, spacing: 24) {
                    previewMap(stage)
                        .frame(width: 320)
                    VStack(alignment: .leading, spacing: 16) {
                        stageInfo(stage)
                        Spacer(minLength: 0)
                        continueButtons
                    }
                }
            } else {
                allClearedContent
            }
        }
        .padding(22)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    /// 챕터 배지 + "NEXT · CHAPTER n 이름" + 스테이지 이름 + 별 3개 기준
    private func stageInfo(_ stage: Stage) -> some View {
        let chapter = ChapterCatalog.chapter(stage.chapter)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(chapter?.color ?? .accentColor)
                    Text("\(stage.chapter)")
                        .font(.system(size: 20, weight: .bold, design: .serif)).italic()
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.isFirstTime ? "FIRST STAGE" : "NEXT STAGE")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).tracking(1.2)
                    Text("챕터 \(stage.chapter) · \(chapter?.title ?? "")")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("STAGE \(stage.chapter)-\(stage.stageNumber)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                Text(stage.name)
                    .font(.system(size: 28, weight: .bold))
            }
            Label("\(stage.starThresholds.threeStar)블럭 이하로 풀면 별 3개", systemImage: "star.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    /// 실제 게임과 같은 SpriteKit 미리보기 맵 — 스테이지가 바뀌면 새로 그림
    private func previewMap(_ stage: Stage) -> some View {
        StagePreviewMapView(stage: stage)
            .id(stage.id)
            .aspectRatio(1.0, contentMode: .fit)
    }

    /// 이어서 하기 + 챕터 둘러보기 (아이폰·맥 홈과 같은 3D 버튼)
    private var continueButtons: some View {
        VStack(spacing: 12) {
            HomeContinueButton(next: vm.nextStage, isFirstTime: vm.isFirstTime) {
                if let next = vm.nextStage {
                    open(.stage(chapter: next.chapter, number: next.stage))
                } else {
                    showChapters(nil)
                }
            }
            HomeBrowseButton { showChapters(nil) }
        }
    }

    /// 모든 스테이지를 깼을 때 — 축하 문구와 퍼즐·챕터 안내
    private var allClearedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.statSealMint)
            VStack(alignment: .leading, spacing: 6) {
                Text("모든 챕터를 완료했어요")
                    .font(.system(size: 26, weight: .bold))
                Text("오늘의 퍼즐과 랜덤 퍼즐로 계속 실력을 다듬어 보세요.\n별을 더 적은 블럭으로 다시 따 보는 것도 좋아요.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            // 이어서 할 스테이지가 없으니 "이어서 하기" 대신 챕터 둘러보기만 (퍼즐은 바로 아래 카드에 있음)
            HomeBrowseButton { showChapters(nil) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 챕터 진행

    /// 챕터 진행 한눈에 보기 — 15개를 격자로 전부 보여 주고, 누르면 그 챕터 화면으로
    private var chapterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("챕터")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button {
                    SoundService.shared.play(.buttonTap)
                    showChapters(nil)
                } label: {
                    HStack(spacing: 2) {
                        Text("지도로 보기")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(chapterSelectVM.chapters) { chapter in
                    chapterTile(chapter)
                }
            }
        }
    }

    /// 챕터 한 칸 — 번호(잠기면 자물쇠) + 이름 + 깬 스테이지 수
    private func chapterTile(_ chapter: ChapterInfo) -> some View {
        let unlocked = chapterSelectVM.isUnlocked(chapter)
        return Button {
            if unlocked {
                SoundService.shared.play(.buttonTap)
                showChapters(chapter.number)
            } else {
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(message: chapterSelectVM.lockMessage(for: chapter), accentColor: chapter.color)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(unlocked ? chapter.color : Color.lockedBackground)
                    if unlocked {
                        Text("\(chapter.number)")
                            .font(.system(size: 20, weight: .bold, design: .serif)).italic()
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(unlocked ? Color.primary : Color.secondary)
                        .lineLimit(1)
                    Text("\(chapterSelectVM.clearedStageCount(chapter))/\(chapter.stageCount) 스테이지")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // 폭은 격자 칸이 정함
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview("아이패드 홈 세로") {
    PadHomeView(vm: HomeViewModel(), chapterSelectVM: ChapterSelectViewModel(), lockInfo: .constant(nil),
                open: { _ in }, showChapters: { _ in })
}
#endif
