//
//  DailyPuzzleCard.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - DailyPuzzleCard
/// 홈의 "오늘의 퍼즐" 카드 — 날짜와 그날의 테마, 완료 상태를 보여 주고 누르면 일일 퍼즐을 시작
/// 오른쪽 주사위 버튼은 기록 없는 연습용 랜덤 퍼즐 (아이폰·아이패드·맥 홈 공용)
struct DailyPuzzleCard: View {

    let info: DailyPuzzleInfo
    var isLocked = false  // 잠금 상태 — 흐리게 + 자물쇠, 눌러도 호출부가 팝업을 띄움
    let onDaily: () -> Void
    let onRandom: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if !isLocked { SoundService.shared.play(.buttonTap) }  // 잠겼으면 호출부가 잠금 사운드
                onDaily()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isLocked ? "lock.fill" : (info.isCleared ? "checkmark.seal.fill" : "sparkles"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(info.isCleared ? Color.gemMint : Color.starGold)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("오늘의 퍼즐")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("\(info.dateText) · \(info.themeTitle)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if info.isCleared {
                        StarRatingView(earned: info.stars, size: 12)
                    } else {
                        Text("도전")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("오늘의 퍼즐, \(info.isCleared ? "완료" : "도전하기")")

            Button {
                if !isLocked { SoundService.shared.play(.buttonTap) }
                onRandom()
            } label: {
                Image(systemName: "dice.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 40, height: 40)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("랜덤 퍼즐")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(isLocked ? 0.5 : 1)  // 잠긴 동안만 흐리게 (열리면 기존 그대로)
    }
}
