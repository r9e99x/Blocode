//
//  StageIcon3D.swift
//  Blocode
//
//  Created by 조준희 on 10/27/26.
//

import SwiftUI

// MARK: - StageIcon3D
/// 스테이지 상태를 보여주는 3D 아이콘 — 잠김(자물쇠) / 클리어(체크) / 그 외(번호)
/// 아이폰 챕터 화면·맥/아이패드 챕터 브라우저 공용 (예전엔 세 화면에 같은 코드가 따로 있었음)
/// 화면마다 다른 것(크기, 눌림 표시, "지금 여기" 아래 뒷면 색)만 매개변수로 받고 나머지는 동일
struct StageIcon3D: View {

    /// 화면별 크기 수치 — 아이콘 한 변·모서리·상태 아이콘 글자 크기
    struct Metrics {
        let size: CGFloat
        let cornerRadius: CGFloat
        let lockFontSize: CGFloat
        let checkFontSize: CGFloat
        let numberFontSize: CGFloat
    }

    let number: Int            // 스테이지 번호
    let locked: Bool           // 잠김 여부
    let cleared: Bool          // 클리어 여부
    let isCurrent: Bool        // 현재 진행 위치("지금 여기") 여부 — 슬레이트 앞면
    let chapterColor: Color    // 열린 스테이지 앞면 색
    let metrics: Metrics
    var isPressed: Bool = false
    /// 눌림 시 앞면에 검정 0.10을 덮을지 (아이폰 챕터 화면만 사용, 브라우저는 내려앉기만)
    var showsPressedOverlay: Bool = false
    /// "지금 여기" 아이콘의 아래 뒷면 색 — nil이면 다른 상태처럼 앞면 + 검정 0.28 (맥/아이패드 브라우저),
    /// 아이폰 챕터 화면은 연한 탄색 단색을 넘김 (플랫폼별로 라이트 외형이 원래 달라 그대로 유지)
    var currentBottomBack: Color? = nil

    @Environment(\.colorScheme) private var colorScheme

    private let topDepth: CGFloat = 1
    private let bottomDepth: CGFloat = 2

    var body: some View {
        let face: Color = locked ? .lockedBackground : (isCurrent ? .slateButtonFace : chapterColor)
        // 잠긴 아이콘은 다크모드에서만 베벨을 완화 (챕터 지도의 잠긴 카드와 동일 — 라이트는 0.32/0.28 유지)
        let lockedDark = locked && colorScheme == .dark
        let r = metrics.cornerRadius

        ThreeDSurface(topDepth: topDepth, bottomDepth: bottomDepth, isPressed: isPressed) {
            // ① 위 뒷면
            ZStack {
                RoundedRectangle(cornerRadius: r).fill(face)
                RoundedRectangle(cornerRadius: r).fill(Color.white.opacity((isCurrent || lockedDark) ? 0.18 : 0.32))
            }
            .frame(width: metrics.size, height: metrics.size)
        } bottomBack: {
            // ② 아래 뒷면 — "지금 여기"이고 단색이 지정됐으면 그 색, 아니면 앞면 + 그림자
            Group {
                if isCurrent, let currentBottomBack {
                    RoundedRectangle(cornerRadius: r).fill(currentBottomBack)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: r).fill(face)
                        RoundedRectangle(cornerRadius: r).fill(Color.black.opacity(lockedDark ? 0.10 : 0.28))
                    }
                }
            }
            .frame(width: metrics.size, height: metrics.size)
        } front: {
            // ③ 앞면 + (눌림 그림자) + 상태 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: r).fill(face)
                if isPressed && showsPressedOverlay {
                    RoundedRectangle(cornerRadius: r).fill(Color.black.opacity(0.10))
                }
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: metrics.lockFontSize))
                        .foregroundStyle(Color.primary.opacity(0.55))
                } else if cleared {
                    Image(systemName: "checkmark")
                        .font(.system(size: metrics.checkFontSize, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: metrics.numberFontSize, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: metrics.size, height: metrics.size)
        }
        .frame(width: metrics.size, height: metrics.size + topDepth + bottomDepth)
    }
}
