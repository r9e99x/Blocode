//
//  ChapterSelectView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - ChapterInfo
/// 챕터 선택 화면에서 사용하는 챕터 정보 모델
private struct ChapterInfo: Identifiable {
    let id: Int                     // 챕터 번호 (1~5)
    var number: Int { id }          // id의 alias — 가독성을 위한 computed property
    let title: String               // 챕터 이름 (예: "기본기")
    let stageCount: Int             // 챕터 내 스테이지 수
    let color: Color                // 챕터 카드 색상
    let requiredStarsFromPrev: Int  // 이전 챕터에서 필요한 최소 별점 (잠금 해제 조건)
}

// MARK: - ChapterSelectView
/// 모든 챕터를 지그재그 맵 형태로 표시하는 화면
struct ChapterSelectView: View {

    @Binding var navPath: NavigationPath  // 뒤로가기 및 다음 화면 이동용
    @ObservedObject private var progress = ProgressService.shared  // 진행도 감지

    /// 챕터 목록 — 순서대로 잠금/해제 상태 계산
    private let chapters: [ChapterInfo] = [
        ChapterInfo(id: 1, title: "기본기",  stageCount: 6,
                    color: Color(red: 0.576, green: 0.788, blue: 0.671), // #93c9ab
                    requiredStarsFromPrev: 0),  // 챕터 1은 잠금 없음
        ChapterInfo(id: 2, title: "변수",   stageCount: 0,
                    color: Color(red: 0.58, green: 0.76, blue: 0.88),
                    requiredStarsFromPrev: 12), // 챕터 1에서 별 12개 이상 필요
        ChapterInfo(id: 3, title: "조건문", stageCount: 0,
                    color: Color(red: 0.93, green: 0.62, blue: 0.42),
                    requiredStarsFromPrev: 0),
        ChapterInfo(id: 4, title: "반복문", stageCount: 0,
                    color: Color(red: 0.45, green: 0.78, blue: 0.62),
                    requiredStarsFromPrev: 0),
        ChapterInfo(id: 5, title: "함수",   stageCount: 0,
                    color: Color(red: 0.88, green: 0.50, blue: 0.68),
                    requiredStarsFromPrev: 0),
    ]

    /// 각 챕터 카드 중심의 X 비율 (지그재그 배치) — 화면 너비 기준 0.0~1.0
    private let xCenterFracs: [CGFloat] = [0.26, 0.70, 0.22, 0.68, 0.30]

    private let cardSize: CGFloat   = 90    // 챕터 카드 크기
    private let rowSpacing: CGFloat = 158   // 카드 상단 간격 (세로 간격)
    private let topPad: CGFloat     = 8     // 맵 상단 패딩

    /// 전체 맵 스크롤 영역 높이 계산
    private var totalMapHeight: CGFloat {
        topPad + CGFloat(chapters.count) * rowSpacing + 60
    }

    /// 스크롤 시 헤더 축소 여부
    @State private var isCompact = false

    var body: some View {
        VStack(spacing: 0) {
            // 고정 헤더 — 스크롤 내려가면 축소
            header

            // 챕터 맵 스크롤 영역
            ScrollView(showsIndicators: false) {
                mapSection
            }
            // 스크롤 위치에 따라 헤더 축소 상태 갱신
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newY in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCompact = newY > 30  // 30pt 이상 스크롤 시 축소
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - 헤더 (고정 + 스크롤 시 축소)

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                // 스크롤 시 "여정" 레이블 숨김 (애니메이션 포함)
                if !isCompact {
                    Text("여정")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                // 타이틀 — 축소 시 폰트 크기 줄어듦
                Text("chapter map")
                    .font(.system(
                        size: isCompact ? 22 : 34,
                        weight: .bold,
                        design: .serif
                    ))
                    .italic()
                    .foregroundStyle(.primary)
            }
            .animation(.easeInOut(duration: 0.18), value: isCompact)

            Spacer()

            // 홈 버튼 — NavigationStack에서 한 단계 뒤로
            Button { navPath.removeLast() } label: {
                Image(systemName: "house")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(cardColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, isCompact ? 14 : 24)
        .animation(.easeInOut(duration: 0.18), value: isCompact)
        .background(Color.appBackground)
        // 축소 시 구분 그림자 표시
        .shadow(
            color: Color.black.opacity(isCompact ? 0.07 : 0),
            radius: 8, x: 0, y: 4
        )
    }

    // MARK: - 맵 영역

    /// 지그재그 배치 챕터 노드와 연결선으로 구성된 맵 영역
    private var mapSection: some View {
        GeometryReader { geo in
            let w = geo.size.width  // 화면 너비 — xCenterFracs 계산 기준

            ZStack(alignment: .topLeading) {

                // 포물선 점선 커넥터 — 챕터 간 연결선
                ForEach(0..<chapters.count - 1, id: \.self) { i in
                    connectorPath(
                        from: CGPoint(
                            x: xCenterFracs[i]     * w,
                            y: topPad + CGFloat(i)     * rowSpacing + cardSize  // 현재 챕터 카드 하단
                        ),
                        to: CGPoint(
                            x: xCenterFracs[i + 1] * w,
                            y: topPad + CGFloat(i + 1) * rowSpacing             // 다음 챕터 카드 상단
                        )
                    )
                }

                // 챕터 노드 (카드 + 레이블 + 별)
                ForEach(Array(chapters.enumerated()), id: \.element.id) { i, ch in
                    chapterNode(ch)
                        // 카드 중심을 xCenterFracs 위치에 맞춤
                        .offset(
                            x: xCenterFracs[i] * w - (cardSize + 20) / 2,
                            y: topPad + CGFloat(i) * rowSpacing
                        )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: totalMapHeight)
        .padding(.bottom, 40)
    }

    // MARK: - 포물선 점선 커넥터

    /// 두 챕터 카드를 연결하는 이차 베지어 곡선 점선
    private func connectorPath(from: CGPoint, to: CGPoint) -> some View {
        // 이차 베지어 곡선: 중간 제어점을 수평 방향 반대로 휘어지게
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        // 좌→우 이동이면 위로, 우→좌 이동이면 아래로 살짝 휨
        let goingRight = to.x > from.x
        let controlPt = CGPoint(
            x: midX + (goingRight ? -30 : 30),
            y: midY
        )

        return Path { p in
            p.move(to: from)
            p.addQuadCurve(to: to, control: controlPt)
        }
        .stroke(
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 9])
        )
        .foregroundStyle(Color.primary.opacity(0.20))
    }

    // MARK: - 챕터 노드 (카드 + 이름 + 별)

    /// 개별 챕터를 표현하는 3D 카드 + 이름 + 별점 요약 뷰
    private func chapterNode(_ chapter: ChapterInfo) -> some View {
        let unlocked = isUnlocked(chapter)     // 잠금 해제 여부
        let earned   = chapterStars(chapter)   // 획득한 별 수

        return VStack(spacing: 7) {

            // 카드
            ZStack(alignment: .topTrailing) {
                // ── 3D 카드 본체 ──────────────────────────────────────
                // ZStack(alignment: .top) 으로 앞면/뒷면 적층
                ZStack(alignment: .top) {

                    // ① 위 뒷면 — 밝게 (앞면보다 위에 살짝 보임)
                    ZStack {
                        RoundedRectangle(cornerRadius: 26).fill(unlocked ? chapter.color : lockedCardColor)
                        RoundedRectangle(cornerRadius: 26).fill(Color.white.opacity(unlocked ? 0.32 : 0.18))
                    }
                    .frame(width: cardSize, height: cardSize)

                    // ② 아래 뒷면 — 어둡게 (그림자 효과)
                    ZStack {
                        RoundedRectangle(cornerRadius: 26).fill(unlocked ? chapter.color : lockedCardColor)
                        RoundedRectangle(cornerRadius: 26).fill(Color.black.opacity(unlocked ? 0.28 : 0.10))
                    }
                    .frame(width: cardSize, height: cardSize)
                    .offset(y: 6)   // topDepth(2) + botDepth(4)

                    // ③ 앞면 — 5pt 내려서 위 뒷면이 보이게
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(unlocked ? chapter.color : lockedCardColor)

                        // 잠금 해제: 챕터 번호 / 잠금: 자물쇠 아이콘
                        if unlocked {
                            Text("\(chapter.number)")
                                .font(.system(size: 48, weight: .bold, design: .serif))
                                .italic()
                                .foregroundStyle(.white.opacity(0.95))
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.primary.opacity(0.30))
                        }
                    }
                    .frame(width: cardSize, height: cardSize)
                    .offset(y: 2)   // topDepth
                }
                .frame(width: cardSize, height: cardSize + 6)

                // 진행 배지 — 스테이지 클리어 수 표시 (예: "3/6")
                if unlocked && chapter.stageCount > 0 {
                    let cleared = clearedStageCount(chapter)
                    Text("\(cleared)/\(chapter.stageCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.13, green: 0.13, blue: 0.13))
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)  // 카드 우상단에 오버레이
                }
            }
            .frame(width: cardSize + 10, height: cardSize + 10)
            .contentShape(Rectangle())
            .onTapGesture {
                // 잠금 해제된 챕터이고 스테이지가 있을 때만 이동
                guard unlocked && chapter.stageCount > 0 else { return }
                navPath.append(AppRoute.chapter(chapter.number))
            }

            // 챕터 이름
            Text(chapter.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(unlocked ? Color.primary : Color.secondary)

            // 별 진행도 (최대 3개로 정규화)
            starsRow(earned: earned, maxStars: max(chapter.stageCount * 3, 3))
                .opacity(unlocked ? 1.0 : 0.35)  // 잠긴 챕터는 흐리게
        }
        .frame(width: cardSize + 20)  // 레이블이 카드보다 조금 넓게
    }

    // MARK: - 별 행

    /// 획득 별을 최대 3개 기준으로 시각화하는 별 행
    private func starsRow(earned: Int, maxStars: Int) -> some View {
        // 비율에 따라 채워진 별 수 계산 (1~3개 범위로 클램핑)
        let filledCount: Int = {
            guard maxStars > 0, earned > 0 else { return 0 }
            return max(1, min(3, Int(Double(earned) / Double(maxStars) * 3 + 0.5)))
        }()

        return HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                // 채워진 별: 골드 / 빈 별: 연한 색
                Image(systemName: i < filledCount ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundStyle(
                        i < filledCount
                            ? Color(red: 0.95, green: 0.72, blue: 0.28)  // 골드
                            : Color.primary.opacity(0.22)                  // 연한 빈 별
                    )
            }
        }
    }

    // MARK: - 헬퍼

    /// 챕터 잠금 해제 여부 확인
    private func isUnlocked(_ chapter: ChapterInfo) -> Bool {
        if chapter.number == 1 { return true }  // 챕터 1은 항상 열림
        // 이전 챕터의 별점이 requiredStarsFromPrev 이상이고 스테이지가 있을 때 열림
        let prevStars = progress.totalStars(chapter: chapter.number - 1, stageCount: 6)
        return prevStars >= chapter.requiredStarsFromPrev && chapter.stageCount > 0
    }

    /// 챕터에서 획득한 총 별점 반환
    private func chapterStars(_ chapter: ChapterInfo) -> Int {
        guard chapter.stageCount > 0 else { return 0 }
        return progress.totalStars(chapter: chapter.number, stageCount: chapter.stageCount)
    }

    /// 챕터에서 클리어한 스테이지 수 반환
    private func clearedStageCount(_ chapter: ChapterInfo) -> Int {
        guard chapter.stageCount > 0 else { return 0 }
        return (1...chapter.stageCount).filter {
            progress.isCleared("ch\(chapter.number)_stage\($0)")
        }.count
    }

    // MARK: - 색상 헬퍼

    /// 홈 버튼 배경색 — 다크/라이트 모드 대응
    private var cardColor: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1.0)
                : UIColor(red: 0.984, green: 0.965, blue: 0.910, alpha: 1.0) // #fbf6e8
        })
    }

    /// 잠긴 챕터 카드 배경색 — 따뜻한 회색 계열
    private var lockedCardColor: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.21, blue: 0.25, alpha: 1.0)
                : UIColor(red: 0.90, green: 0.87, blue: 0.82, alpha: 1.0) // 따뜻한 회색
        })
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var path = NavigationPath()
    ChapterSelectView(navPath: $path)
}
