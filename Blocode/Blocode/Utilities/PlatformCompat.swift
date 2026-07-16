//
//  PlatformCompat.swift
//  Blocode
//
//  Created by 조준희 on 7/2/26.
//

import SwiftUI

// MARK: - 레이아웃 브레이크포인트
/// 화면 폭 기준 레이아웃 분기점
/// - 아이폰(최대 ~440pt): 컴팩트(기존 세로 스택) 레이아웃
/// - 아이패드 세로(744pt~)/가로·맥 윈도우: 와이드(분할) 레이아웃
/// - 아이패드 Split View로 좁아지면 자동으로 컴팩트 레이아웃 폴백
enum LayoutBreakpoint {
    /// 와이드(분할) 레이아웃 적용 최소 폭
    static let wide: CGFloat = 700
}

// MARK: - 플랫폼 호환 View 헬퍼
// iOS 전용 API를 macOS에서도 컴파일되도록 감싸는 얇은 래퍼 모음
// (iOS 동작은 기존과 동일하게 유지하고, macOS에서는 대체 동작 또는 no-op 적용)

extension View {

    /// 내비게이션 바 숨김
    /// iOS: 기존과 동일하게 내비게이션 바를 숨김 / macOS: 해당 개념이 없으므로 no-op
    @ViewBuilder
    func hideNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    /// 전체 화면 모달 표시
    /// iOS: fullScreenCover 그대로 사용 / macOS: fullScreenCover 미지원이라 sheet로 대체
    @ViewBuilder
    func fullScreenCoverCompat<CoverContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> CoverContent
    ) -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: isPresented, content: content)
        #else
        self.sheet(isPresented: isPresented, content: content)
        #endif
    }
}
