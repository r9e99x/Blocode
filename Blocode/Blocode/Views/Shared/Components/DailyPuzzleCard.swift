//
//  DailyPuzzleCard.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - DailyPuzzleCard
/// 홈의 퍼즐 카드 묶음 (아이폰·아이패드·맥 홈 공용)
///  - "오늘의 퍼즐": 날짜와 그날의 테마, 완료 상태를 보여 주고 누르면 일일 퍼즐을 시작
///  - "랜덤 퍼즐": 바로 아래 별도 카드, 기록 없는 연습용 퍼즐
struct DailyPuzzleCard: View {

    let info: DailyPuzzleInfo
    var isLocked = false  // 잠금 상태 — 흐리게 + 자물쇠, 눌러도 호출부가 팝업을 띄움
    var isCompact = false  // 세로가 모자란 화면(아이폰 가로) — 두 카드를 반 크기로 한 줄에 나란히
    let onDaily: () -> Void
    let onRandom: () -> Void

    var body: some View {
        Group {
            if isCompact {
                HStack(spacing: 10) {
                    dailyCard
                    randomCard
                }
            } else {
                VStack(spacing: 10) {
                    dailyCard
                    randomCard
                }
            }
        }
        .opacity(isLocked ? 0.5 : 1)  // 잠긴 동안만 흐리게 (열리면 기존 그대로)
    }

    /// 카드 공통 바깥 모양 — 두 카드가 같은 톤을 쓰도록 한 곳에서 관리
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, isCompact ? 10 : 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)  // 한 줄 배치에서 두 카드가 같은 폭
            .background(Color.statCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 오늘의 퍼즐 카드 — 카드 전체가 일일 퍼즐 버튼
    private var dailyCard: some View {
        Button {
            if !isLocked { SoundService.shared.play(.buttonTap) }  // 잠겼으면 호출부가 잠금 사운드
            onDaily()
        } label: {
            card {
                HStack(spacing: isCompact ? 8 : 12) {
                    Image(systemName: isLocked ? "lock.fill" : (info.isCleared ? "checkmark.seal.fill" : "sparkles"))
                        .font(.system(size: isCompact ? 17 : 20, weight: .semibold))
                        .foregroundStyle(info.isCleared ? Color.gemMint : Color.starGold)
                        .frame(width: isCompact ? 22 : 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("오늘의 퍼즐")
                            .font(.system(size: isCompact ? 14 : 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        // 좁은 한 줄 배치에선 날짜를 빼고 테마만 보여 줌
                        Text(isCompact ? info.themeTitle : "\(info.dateText) · \(info.themeTitle)")
                            .font(.system(size: isCompact ? 11 : 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if isCompact {
                        if info.isCleared { StarRatingView(earned: info.stars, size: 9) }
                    } else if info.isCleared {
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오늘의 퍼즐, \(info.isCleared ? "완료" : "도전하기")")
    }

    /// 랜덤 퍼즐 카드 — 누를 때마다 새 퍼즐, 기록 없는 연습용
    private var randomCard: some View {
        Button {
            if !isLocked { SoundService.shared.play(.buttonTap) }
            onRandom()
        } label: {
            card {
                HStack(spacing: isCompact ? 8 : 12) {
                    Image(systemName: isLocked ? "lock.fill" : "dice.fill")
                        .font(.system(size: isCompact ? 17 : 20, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: isCompact ? 22 : 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("랜덤 퍼즐")
                            .font(.system(size: isCompact ? 14 : 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(isCompact ? "연습용" : "기록 없이 연습해요")
                            .font(.system(size: isCompact ? 11 : 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if !isCompact {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("랜덤 퍼즐")
    }
}
