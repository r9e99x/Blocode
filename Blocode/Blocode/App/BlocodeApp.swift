//
//  BlocodeApp.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI
import SwiftData

// 앱 진입점 — @main 어트리뷰트로 SwiftUI 앱의 시작점을 지정
@main
struct BlocodeApp: App {

    // MARK: - SwiftData 컨테이너 설정
    /// 유저 진행 상황을 영구 저장하는 SwiftData 컨테이너
    var sharedModelContainer: ModelContainer = {
        // 저장할 모델 스키마 정의
        let schema = Schema([
            StageProgress.self,
        ])
        // 영구 저장 설정 (isStoredInMemoryOnly: false = 앱 종료 후에도 데이터 유지)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // 영구 저장 (앱 종료 후에도 유지)
        )

        do {
            // 스키마와 설정으로 ModelContainer 생성 시도
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 컨테이너 생성 실패 시 앱 종료 (치명적 오류)
            fatalError("SwiftData 컨테이너 생성 실패: \(error)")
        }
    }()

    // MARK: - 온보딩 표시 여부
    /// 앱 최초 설치 시 false → 온보딩 표시 후 true로 저장
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: - 앱 진입점
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                // 온보딩 완료 → 홈 화면
                ContentView()
            } else {
                // 첫 실행 → 온보딩 화면
                OnboardingView {
                    hasSeenOnboarding = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
