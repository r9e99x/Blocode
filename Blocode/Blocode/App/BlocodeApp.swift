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

    // MARK: - 앱 진입점
    var body: some Scene {
        // 단일 윈도우 그룹으로 앱 화면 구성
        WindowGroup {
            // 앱 시작 시 홈 화면으로 진입
            ContentView()
        }
        // 모든 하위 뷰에서 SwiftData 컨테이너를 사용할 수 있도록 환경에 주입
        .modelContainer(sharedModelContainer)
    }
}
