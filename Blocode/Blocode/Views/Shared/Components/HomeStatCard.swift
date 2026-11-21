//
//  HomeStatCard.swift
//  Blocode
//
//  Created by 조준희 on 11/21/26.
//

import SwiftUI

// MARK: - HomeStatCard
/// 홈 통계 카드 한 장 — 아이콘 + 굵은 숫자 + 작은 레이블 (획득 별·챕터 완료·연속)
/// 아이폰 홈과 아이패드·맥 셸 홈이 함께 씀 (예전엔 두 화면에 크기가 조금씩 다른 두 벌이 있었음 — 사용자 결정으로 아이폰 모양에 맞춰 통일)
struct HomeStatCard: View {

    let icon: String       // SF Symbol 이름
    let iconColor: Color   // 아이콘 색
    let value: String      // 큰 숫자 (예: "12/312")
    let label: String      // 아래 레이블 (예: "획득 별")

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.statCardBackground)  // 팔레트와 같은 크림색 카드
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
