//
//  ChapterHeaderCard.swift
//  Blocode
//
//  Created by 조준희 on 10/19/26.
//

import SwiftUI

// MARK: - ChapterHeaderCard
/// 챕터 색 헤더 카드 — "CHAPTER 02" + 제목 + 줄바꿈 별 행 + "N / M stars", 앞/뒤 2겹 depth로 입체감
/// iOS 챕터 화면 가로모드·맥/아이패드 챕터 브라우저 공용 (예전엔 세 화면에 같은 코드가 따로 있었음)
/// 바깥 여백은 화면마다 달라서 호출부가 직접 붙임
struct ChapterHeaderCard: View {
    let chapterNumber: Int  // 챕터 번호 ("CHAPTER 02" 표시용)
    let title: String       // 챕터 제목
    let color: Color        // 챕터 색 (카드 앞/뒷면)
    let earned: Int         // 챕터에서 획득한 별 수
    let maxStars: Int       // 챕터 최대 별 수 (스테이지 수 × 3)

    private let depth: CGFloat = 5  // 3D 효과 깊이

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHAPTER \(String(format: "%02d", chapterNumber))")
                .font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.7)).tracking(1)
            Text(title).font(.system(size: 24, weight: .bold)).foregroundStyle(.white)

            HStack(alignment: .top, spacing: 8) {
                // 별이 많은 챕터는 한 줄에 다 안 들어가므로 자동으로 다음 줄로 감싸는 레이아웃 사용
                WrappingStarRow(earned: earned, total: maxStars, size: 9, spacing: 2, lineSpacing: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(earned) / \(maxStars)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("stars")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .fixedSize()
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16 + depth)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .top) {
                // 뒷면 — 어둡게, depth만큼 아래로 (3D 효과)
                RoundedRectangle(cornerRadius: 16).fill(color)
                    .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.28)))
                    .padding(.top, depth)
                // 앞면 — depth만큼 짧게 (뒷면이 아래로 보이게)
                RoundedRectangle(cornerRadius: 16).fill(color)
                    .padding(.bottom, depth)
            }
        }
    }
}
