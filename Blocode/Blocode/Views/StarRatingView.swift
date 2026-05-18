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
