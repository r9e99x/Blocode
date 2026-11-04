//
//  ChapterMapView.swift
//  Blocode
//
//  Created by 조준희 on 11/1/26.
//

import SwiftUI

// MARK: - ChapterMapView
/// 챕터를 세로로 나열하며 좌우로 지그재그 배치하는 지도 — 곡선 점선 + 3D 챕터 카드 + 이름 + 별
/// 아이폰 챕터 선택·아이패드/맥 셸 공용 (예전엔 세 화면에 같은 코드가 따로 있었음)
/// 화면 제목과 스크롤은 화면마다 달라서 호출부가 담당
struct ChapterMapView: View {

    /// 화면별 크기 수치
    struct Metrics {
        let cardSize: CGFloat        // 챕터 카드 한 변
        let rowSpacing: CGFloat      // 카드 상단 간격 (세로 간격)
        let cornerRadius: CGFloat    // 카드 모서리 반지름
        let numberFontSize: CGFloat  // 챕터 번호 글자 크기
        let lockFontSize: CGFloat    // 자물쇠 크기
    }

    @ObservedObject var vm: ChapterSelectViewModel  // 챕터 목록·잠금·별 계산
    let metrics: Metrics
    var showsProgressBadge: Bool = false            // 카드 우상단 "클리어 수/전체" 배지 (아이폰만 사용)
    @Binding var lockInfo: LockInfo?                // 잠긴 카드 탭 시 채움 — 팝업 표시 위치는 호출부가 결정
    let onOpen: (Int) -> Void                       // 열린 카드 탭 시 챕터 번호 전달

    @State private var pressedChapterId: Int? = nil  // 눌린 카드 ID 추적
    @Environment(\.colorScheme) private var colorScheme  // 잠긴 카드 자물쇠 밝기를 다크에서만 높이는 데 사용

    /// 각 챕터 카드 중심의 X 비율 — 화면 너비 기준 0.0~1.0
    /// 10개를 순환 — 5개만 두고 순환시키면 인덱스4→5 전환에서
    /// 좌우 진폭이 거의 없어져(0.30→0.26) 지그재그가 끊겨 보이는 문제가 있었음
    private let xCenterFracs: [CGFloat] = [0.26, 0.70, 0.22, 0.68, 0.30, 0.72, 0.24, 0.66, 0.28, 0.74]
    private let topPad: CGFloat = 8  // 지도 상단 패딩

    /// 챕터 인덱스의 X 비율 — 챕터 수가 배열 길이를 넘어도 순환 접근해 인덱스 크래시 방지
    private func xCenterFrac(_ index: Int) -> CGFloat {
        xCenterFracs[index % xCenterFracs.count]
    }

    var body: some View {
        let chapters = vm.chapters
        let size = metrics.cardSize
        let row = metrics.rowSpacing

        GeometryReader { geo in
            let w = geo.size.width  // 지도 너비 — xCenterFracs 계산 기준

            ZStack(alignment: .topLeading) {
                // 곡선 점선 — 챕터 간 연결선
                ForEach(0..<max(chapters.count - 1, 0), id: \.self) { i in
                    connectorPath(
                        from: CGPoint(x: xCenterFrac(i) * w, y: topPad + CGFloat(i) * row + size),  // 현재 카드 하단
                        to: CGPoint(x: xCenterFrac(i + 1) * w, y: topPad + CGFloat(i + 1) * row)    // 다음 카드 상단
                    )
                }

                // 챕터 노드 — 카드 중심을 xCenterFracs 위치에 맞춤
                // (노드 실제 폭 size + 20과 일치시켜야 점선 연결점이 카드 중심에서 어긋나지 않음)
                ForEach(Array(chapters.enumerated()), id: \.element.id) { i, chapter in
                    chapterNode(chapter)
                        .offset(x: xCenterFrac(i) * w - (size + 20) / 2, y: topPad + CGFloat(i) * row)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: topPad + CGFloat(chapters.count) * row + 60)
        .padding(.bottom, 40)
    }

    // MARK: - 곡선 점선

    /// 두 챕터 카드를 연결하는 이차 베지어 곡선 점선 (좌→우 이동이면 위로, 우→좌 이동이면 아래로 살짝 휨)
    private func connectorPath(from: CGPoint, to: CGPoint) -> some View {
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let goingRight = to.x > from.x
        let controlPt = CGPoint(x: midX + (goingRight ? -30 : 30), y: midY)

        return Path { p in
            p.move(to: from)
            p.addQuadCurve(to: to, control: controlPt)
        }
        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 9]))
        .foregroundStyle(Color.primary.opacity(0.20))
    }

    // MARK: - 챕터 노드 (카드 + 이름 + 별)

    private func chapterNode(_ chapter: ChapterInfo) -> some View {
        let unlocked = vm.isUnlocked(chapter)

        return VStack(spacing: 7) {
            cardArea(chapter, unlocked: unlocked)
                .contentShape(Rectangle())
                .onTapGesture {
                    if unlocked && chapter.stageCount > 0 {
                        SoundService.shared.play(.buttonTap)
                        onOpen(chapter.number)
                    } else if !unlocked {
                        // 잠긴 챕터: 전용 잠금 사운드 + 해금 조건 팝업 표시
                        SoundService.shared.play(.lockButton)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            lockInfo = LockInfo(message: vm.lockMessage(for: chapter),
                                                accentColor: chapter.color)
                        }
                    }
                }
                // 눌림 상태 추적 — 탭과 동시 실행
                .onPressState(isPressed: Binding(
                    get: { pressedChapterId == chapter.id },
                    set: { pressed in pressedChapterId = pressed ? chapter.id : nil }
                ))

            // 챕터 이름
            Text(chapter.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(unlocked ? Color.primary : Color.secondary)

            // 별 진행도 (비율 기반으로 최대 3개 표시 — 환산 계산은 VM 담당)
            StarRatingView(earned: vm.displayStarCount(chapter), size: 11)
                .opacity(unlocked ? 1.0 : 0.35)  // 잠긴 챕터는 흐리게
        }
        .frame(width: metrics.cardSize + 20)  // 이름이 카드보다 조금 넓게
    }

    /// 카드 영역 — 배지를 쓰는 화면은 배지가 튀어나올 자리까지 포함한 프레임으로 감쌈
    @ViewBuilder
    private func cardArea(_ chapter: ChapterInfo, unlocked: Bool) -> some View {
        if showsProgressBadge {
            ZStack(alignment: .topTrailing) {
                card3D(chapter, unlocked: unlocked)

                // 진행 배지
                if unlocked && chapter.stageCount > 0 {
                    Text("\(vm.clearedStageCount(chapter))/\(chapter.stageCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.13, green: 0.13, blue: 0.13))
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
            .frame(width: metrics.cardSize + 10, height: metrics.cardSize + 10)
        } else {
            card3D(chapter, unlocked: unlocked)
        }
    }

    /// 3D 챕터 카드 — 번호 또는 자물쇠
    private func card3D(_ chapter: ChapterInfo, unlocked: Bool) -> some View {
        let isPressed = pressedChapterId == chapter.id
        let size = metrics.cardSize
        let r = metrics.cornerRadius
        let face = unlocked ? chapter.color : Color.lockedBackground
        let topD: CGFloat = 2   // 위 뒷면 두께
        let botD: CGFloat = 4   // 아래 뒷면 두께

        return ThreeDSurface(topDepth: topD, bottomDepth: botD, isPressed: isPressed) {
            // ① 위 뒷면
            ZStack {
                RoundedRectangle(cornerRadius: r).fill(face)
                RoundedRectangle(cornerRadius: r).fill(Color.white.opacity(unlocked ? 0.32 : 0.18))
            }
            .frame(width: size, height: size)
        } bottomBack: {
            // ② 아래 뒷면
            ZStack {
                RoundedRectangle(cornerRadius: r).fill(face)
                RoundedRectangle(cornerRadius: r).fill(Color.black.opacity(unlocked ? 0.28 : 0.10))
            }
            .frame(width: size, height: size)
        } front: {
            // ③ 앞면 — 색 + (눌림 시 그림자) + 번호/잠금
            ZStack {
                RoundedRectangle(cornerRadius: r).fill(face)
                if isPressed {
                    RoundedRectangle(cornerRadius: r).fill(Color.black.opacity(0.10))
                }
                if unlocked {
                    Text("\(chapter.number)")
                        .font(.system(size: metrics.numberFontSize, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.95))
                } else {
                    // 자물쇠 밝기 — 라이트: 0.30 / 다크: 스테이지 잠금 아이콘과 동일한 0.55
                    Image(systemName: "lock.fill")
                        .font(.system(size: metrics.lockFontSize))
                        .foregroundStyle(Color.primary.opacity(colorScheme == .dark ? 0.55 : 0.30))
                }
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size + topD + botD)
    }
}
