//
//  OnboardingView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - OnboardingPage 모델
/// 온보딩 슬라이드 한 장의 데이터
private struct OnboardingPage {
    let illustration: AnyView  // 슬라이드별 일러스트 뷰
    let title: String          // 큰 제목 (Georgia Italic)
    let description: String    // 설명 텍스트
}

// MARK: - OnboardingView
/// 앱 첫 실행 시 표시되는 온보딩 화면
/// UserDefaults의 "hasSeenOnboarding" 키로 표시 여부를 관리
struct OnboardingView: View {

    /// 온보딩 완료 콜백 — BlocodeApp에서 ContentView로 전환하는 데 사용
    var onFinish: () -> Void

    /// 현재 표시 중인 슬라이드 인덱스
    @State private var currentPage = 0

    // MARK: - 슬라이드 데이터
    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                illustration: AnyView(welcomeIllustration),
                title: "Blocode에\n오신 걸 환영해요.",
                description: "블럭으로 코드를 짜고\n캐릭터를 움직여보세요."
            ),
            OnboardingPage(
                illustration: AnyView(blockIllustration),
                title: "블럭을 탭해\n코드를 만드세요",
                description: "팔레트에서 블럭을 탭하면 추가되고,\n드래그해서 순서를 바꿀 수 있어요."
            ),
            OnboardingPage(
                illustration: AnyView(runIllustration),
                title: "실행 버튼으로\n캐릭터를 움직여요",
                description: "블럭 순서대로 캐릭터가 움직여요.\n목표 지점에 도달하면 클리어!"
            ),
            OnboardingPage(
                illustration: AnyView(starIllustration),
                title: "별을 모아\n스테이지를 클리어해요",
                description: "적은 블럭으로 클리어할수록\n더 많은 별을 얻을 수 있어요."
            ),
        ]
    }

    // MARK: - 본문

    var body: some View {
        ZStack {
            // 앱 배경색
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: 상단 바 (페이지 카운터 + 건너뛰기)
                topBar

                // MARK: 슬라이드 콘텐츠 (탭뷰로 스와이프)
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageContent(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // MARK: 하단 (점 인디케이터 + 버튼)
                bottomBar
            }
        }
    }

    // MARK: - 상단 바

    private var topBar: some View {
        HStack {
            Spacer()

            // 건너뛰기 버튼 — 오른쪽 정렬
            Button {
                finish()
            } label: {
                Text("건너뛰기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .opacity(currentPage < pages.count - 1 ? 1 : 0)  // 마지막 슬라이드에서는 숨김
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 슬라이드 콘텐츠

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {

            Spacer()

            // 일러스트 영역
            page.illustration
                .frame(height: 280)

            Spacer()

            // 텍스트 영역 — 하단 정렬
            VStack(alignment: .leading, spacing: 10) {
                // 큰 제목 — Georgia Italic + 기울임 변환
                Text(page.title)
                    .font(.custom("Georgia-Italic", size: 36))
                    .foregroundStyle(.primary)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.10, d: 1, tx: 0, ty: 0))
                    .fixedSize(horizontal: false, vertical: true)

                // 설명 텍스트
                Text(page.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.bottom, 32)
        }
    }

    // MARK: - 하단 바

    private var bottomBar: some View {
        VStack(spacing: 20) {

            // 점 인디케이터
            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i == currentPage ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: i == currentPage ? 18 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
            }

            // 다음 / 시작하기 버튼
            nextButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - 다음 버튼 (3D 다크 스타일)

    @State private var isNextPressed = false

    private var nextButton: some View {
        let frontH:  CGFloat = 56
        let topD:    CGFloat = 0.8
        let botD:    CGFloat = 2.5
        let cr:      CGFloat = 18
        let isLast   = currentPage == pages.count - 1
        let label    = isLast ? "시작하기" : "다음  ›"

        // 어두운 다크 버튼 색상
        let frontColor   = Color.darkInk
        let topBackColor = Color.bevelTopBack
        let botBackColor = Color.bevelBottomBack

        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                if isLast { finish() }
                else { currentPage += 1 }
            }
        } label: {
            ThreeDSurface(topDepth: topD, bottomDepth: botD, isPressed: isNextPressed) {
                // ① 위 뒷면
                RoundedRectangle(cornerRadius: cr)
                    .fill(topBackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: frontH)
            } bottomBack: {
                // ② 아래 뒷면
                RoundedRectangle(cornerRadius: cr)
                    .fill(botBackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: frontH)
            } front: {
                // ③ 앞면 + 텍스트
                ZStack {
                    RoundedRectangle(cornerRadius: cr).fill(frontColor)
                    if isNextPressed {
                        RoundedRectangle(cornerRadius: cr).fill(Color.black.opacity(0.10))
                    }
                    Text(label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: frontH)
            }
            .frame(maxWidth: .infinity)
            .frame(height: frontH + topD + botD)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { isNextPressed = true } }
            .onEnded   { _ in withAnimation(.easeInOut(duration: 0.08)) { isNextPressed = false } }
        )
    }

    // MARK: - 온보딩 완료 처리

    /// UserDefaults에 완료 기록 후 콜백 호출
    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        onFinish()
    }

    // MARK: - 슬라이드 일러스트

    // ① 환영 일러스트 — 앱 아이콘 + 장식 별
    private var welcomeIllustration: some View {
        ZStack {
            // 장식 원형 배경
            Circle()
                .fill(Color(red: 147/255, green: 201/255, blue: 163/255).opacity(0.18))
                .frame(width: 200, height: 200)

            VStack(spacing: 16) {
                // 미니 3D 블럭 아이콘 (홈 화면과 동일)
                miniBlockIcon(size: 72, topD: 1.5, botD: 2.5, cr: 18)

                Text("Blocode")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("block by block.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // 장식 별
            Text("✦")
                .font(.system(size: 14))
                .foregroundStyle(Color.bevelBottomBack)
                .offset(x: -90, y: -60)
            Text("✦")
                .font(.system(size: 9))
                .foregroundStyle(Color.bevelBottomBack)
                .offset(x: 85, y: -80)
            Text("✦")
                .font(.system(size: 11))
                .foregroundStyle(Color.bevelBottomBack)
                .offset(x: 100, y: 20)
        }
        .frame(maxWidth: .infinity)
    }

    // ② 블럭 일러스트 — 코드 블럭 목록 모형
    private var blockIllustration: some View {
        VStack(spacing: 0) {
            // 코드 카드 모형
            VStack(spacing: 0) {
                mockBlockRow(number: 1, label: "앞으로",
                             color: Color(red: 124/255, green: 196/255, blue: 158/255),
                             icon: "arrow.up")
                Divider().opacity(0.3)
                mockBlockRow(number: 2, label: "repeat  3",
                             color: Color(red: 168/255, green: 141/255, blue: 192/255),
                             icon: "repeat")
                Divider().opacity(0.3)
                mockBlockRow(number: 3, label: "앞으로",
                             color: Color(red: 124/255, green: 196/255, blue: 158/255),
                             icon: "arrow.up")
                Divider().opacity(0.3)
                mockBlockRow(number: 4, label: "오른쪽 회전",
                             color: Color(red: 142/255, green: 176/255, blue: 200/255),
                             icon: "arrow.turn.up.right")
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
            .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
    }

    /// 블럭 행 모형 — 실제 BlockRowView 없이 간단히 표현
    private func mockBlockRow(number: Int, label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            // 번호
            Text("\(number)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .trailing)

            // 3D 블럭 (단순화)
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // ③ 실행 일러스트 — 실행 버튼 + 캐릭터 이동 표시
    private var runIllustration: some View {
        VStack(spacing: 24) {
            // 실행 버튼 모형 (3D 스타일)
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(red: 124/255, green: 196/255, blue: 158/255).opacity(0.3))
                    .frame(width: 160, height: 56)
                    .offset(y: 4)

                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(red: 124/255, green: 196/255, blue: 158/255))
                    .frame(width: 160, height: 56)

                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("실행")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
            }

            // 이동 방향 화살표 이미지
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            Color(red: 124/255, green: 196/255, blue: 158/255)
                                .opacity(1.0 - Double(i) * 0.2)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // ④ 별 일러스트 — 별 3개 + 클리어 카드
    private var starIllustration: some View {
        VStack(spacing: 20) {
            // 별 3개
            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: i == 1 ? 52 : 36))
                        .foregroundStyle(Color(red: 242/255, green: 183/255, blue: 64/255))
                        .offset(y: i == 1 ? -10 : 0)
                        .shadow(color: Color(red: 242/255, green: 183/255, blue: 64/255).opacity(0.35),
                                radius: 8, x: 0, y: 4)
                }
            }

            // 클리어 배지
            Text("CLEAR!")
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color(red: 124/255, green: 196/255, blue: 158/255))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(red: 124/255, green: 196/255, blue: 158/255).opacity(0.15))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 미니 블럭 아이콘 (환영 슬라이드용)

    /// 홈 화면과 동일한 3D 블럭 아이콘
    private func miniBlockIcon(size: CGFloat, topD: CGFloat, botD: CGFloat, cr: CGFloat) -> some View {
        let frontColor   = Color.darkInk
        let topBackColor = Color.bevelTopBack
        let botBackColor = Color.bevelBottomBack
        let arrowColor   = Color.arrowCream

        return ThreeDSurface(topDepth: topD, bottomDepth: botD) {
            RoundedRectangle(cornerRadius: cr).fill(topBackColor)
                .frame(width: size, height: size)
        } bottomBack: {
            RoundedRectangle(cornerRadius: cr).fill(botBackColor)
                .frame(width: size, height: size)
        } front: {
            ZStack {
                RoundedRectangle(cornerRadius: cr).fill(frontColor)
                Image(systemName: "arrow.up")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(arrowColor)
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size + topD + botD)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onFinish: {})
}
