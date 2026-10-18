//
//  StarRatingView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - StarRatingView
/// 별점을 시각적으로 표시하는 공통 컴포넌트
/// 획득한 별 수에 따라 채워진 별 / 빈 별을 나열함
///
/// 사용 예:
/// ```swift
/// StarRatingView(earned: 2, total: 3)           // ★★☆ (14pt)
/// StarRatingView(earned: 5, total: 18, size: 10) // 챕터 헤더용 작은 별
/// ```
struct StarRatingView: View {

    /// 현재 획득한 별 수
    let earned: Int

    /// 표시할 전체 별 수 (기본 3개 — 스테이지/챕터 아이콘 표준)
    var total: Int = 3

    /// 별 아이콘 크기 (pt)
    var size: CGFloat = 14

    /// 별 사이 간격 (pt)
    var spacing: CGFloat = 3

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < earned ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(
                        i < earned
                            ? Color.starGold          // 획득한 별 — 골드
                            : Color.primary.opacity(0.20)  // 빈 별 — 연한 색
                    )
            }
        }
    }
}

// MARK: - WrappingStarRow
/// 폭을 넘으면 다음 줄로 자동 줄바꿈되는 별 행 — 별이 많은 챕터 헤더용 (StarRatingView는 한 줄 고정이라 넘침)
/// (iOS 챕터 화면·맥/아이패드 챕터 브라우저·챕터 헤더 카드 공용, 별 색은 StarRatingView와 동일)
struct WrappingStarRow: View {
    let earned: Int             // 획득한 별 수
    let total: Int              // 표시할 전체 별 수
    var size: CGFloat = 9       // 별 아이콘 크기
    var spacing: CGFloat = 2    // 같은 줄 별 사이 간격
    var lineSpacing: CGFloat = 4  // 줄 사이 간격

    var body: some View {
        WrapLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < earned ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i < earned ? Color.starGold : Color.primary.opacity(0.20))
            }
        }
    }
}

// MARK: - WrapLayout
/// 자식 뷰를 가로로 채우다가 폭을 넘으면 다음 줄로 감싸는 간단한 flow 레이아웃
/// (예전엔 iOS·맥·아이패드 파일마다 같은 사본이 있었음 — 하나로 통합)
struct WrapLayout: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        y += lineHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StarRatingView(earned: 0, total: 3)
        StarRatingView(earned: 1, total: 3)
        StarRatingView(earned: 2, total: 3)
        StarRatingView(earned: 3, total: 3)
        StarRatingView(earned: 7, total: 18, size: 10, spacing: 2)
    }
    .padding()
}
