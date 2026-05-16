//
//  ContentView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - ContentView (홈 화면)
/// 앱 실행 시 가장 먼저 보이는 홈 화면
/// NavigationStack의 루트 — 모든 화면 전환은 navPath로 제어
struct ContentView: View {

    /// 앱 전역 내비게이션 경로 — append로 이동, removeLast로 뒤로가기
    @State private var navPath = NavigationPath()

    /// 설정 시트 표시 여부 — true이면 SettingsView를 fullScreenCover로 표시
    @State private var showSettings = false

    /// 테마 변경 감지 — SettingsService 변경 시 뷰 자동 갱신
    @ObservedObject private var settings = SettingsService.shared

    // iOS/macOS 모두 호환되는 배경 반전 색상 (버튼 텍스트용)
    private var buttonForegroundColor: Color {
        #if os(macOS)
        // macOS는 NSColor.windowBackgroundColor를 버튼 텍스트 색상으로 사용
        return Color(NSColor.windowBackgroundColor)
        #else
        // iOS는 systemBackground(흰/검)를 버튼 텍스트 색상으로 사용
        return Color(UIColor.systemBackground)
        #endif
    }

    var body: some View {
        // 루트 NavigationStack — path 바인딩으로 화면 전환 관리
        NavigationStack(path: $navPath) {
            homeContent
                // MARK: 라우트별 목적지 등록
                .navigationDestination(for: AppRoute.self) { route in
                    // 라우트 종류에 따라 적절한 뷰로 이동
                    switch route {
                    case .chapterSelect:
                        // 챕터 선택 화면으로 이동
                        ChapterSelectView(navPath: $navPath)

                    case .chapter(let number):
                        // 특정 챕터 화면으로 이동
                        ChapterView(navPath: $navPath, chapter: number)

                    case .stage(let chapter, let number):
                        // JSON에서 스테이지 데이터를 로드하여 게임 화면으로 이동
                        if let stage = StageLoader.load(chapter: chapter, stage: number) {
                            StageView(stage: stage, navPath: $navPath)
                                .id(stage.id)  // id를 지정하여 같은 스테이지 재진입 시 뷰 갱신 강제
                        }
                    }
                }
        }
        // 설정에 따라 라이트/다크/시스템 테마 적용
        .preferredColorScheme(settings.theme.colorScheme)
        // 설정 화면 — fullScreenCover로 모달 표시
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - 홈 화면 콘텐츠

    private var homeContent: some View {
        VStack(spacing: 40) {

            Spacer()

            // MARK: 앱 로고 영역
            VStack(spacing: 12) {
                // 앱 이름 타이틀
                Text("Blocode")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // 앱 슬로건
                Text("block by block.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // MARK: 버튼 영역
            VStack(spacing: 16) {
                // 시작하기 → 챕터 선택 화면으로 이동
                Button {
                    navPath.append(AppRoute.chapterSelect)
                } label: {
                    Text("시작하기")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)        // 가로 전체 너비 사용
                        .padding(.vertical, 16)
                        .background(Color.primary)         // 다크모드: 흰색, 라이트모드: 검정
                        .foregroundStyle(buttonForegroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // 설정 화면 열기 버튼
                Button {
                    showSettings = true
                } label: {
                    Text("설정")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground.ignoresSafeArea())  // 앱 전체 배경색 적용
        .navigationBarHidden(true)                          // 기본 내비게이션 바 숨김
    }
}

#Preview {
    ContentView()
}
