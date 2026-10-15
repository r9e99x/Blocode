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

    // MARK: - SwiftData 컨테이너
    /// 진행도 저장용 SwiftData 컨테이너는 ProgressService가 소유/생성함.
    /// 여기서는 그 단일 인스턴스를 그대로 주입받아 스토어를 일원화한다.
    /// (이렇게 하면 ProgressService의 쓰기와 추후 커스텀 맵 @Query가
    ///  동일한 컨테이너/스토어를 공유 → 데이터 불일치 방지)
    ///
    /// iCloud 동기화: 현재 비활성. Apple Developer 등록이 필요한 기능이라
    /// 등록 완료 후 ProgressService의 ModelConfiguration에 CloudKit을
    /// 연결하면 활성화됨 (UI의 "iCloud 동기화" 토글도 그때 잠금 해제 예정).
    ///
    /// 커스텀 맵/블럭(유저 제작): 추후 구현 예정. 기본 스테이지는 계속
    /// JSON(Resources/Stages)으로 관리하고, 유저가 만든 커스텀 맵만
    /// 별도 SwiftData 모델(@Model)을 추가해 이 컨테이너 스키마에 등록할 것.

    // MARK: - 온보딩 표시 여부
    /// 앱 최초 설치 시 false → 온보딩 표시 후 true로 저장
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    /// 앱 활성/백그라운드 상태 — 홈 화면으로 나가면 배경음악을 멈추고, 돌아오면 다시 재생하는 데 사용
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - 앱 진입점
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    #if os(macOS)
                    // macOS 전용 최상위 화면 — 좌측 고정 사이드바 + 우측 콘텐츠 전환
                    // (iOS/iPadOS는 이 분기를 전혀 컴파일하지 않음 — ContentView는 완전히 그대로 유지)
                    MacContentShell()
                    #else
                    // 온보딩 완료 → 홈 화면
                    ContentView()
                    #endif
                } else {
                    // 첫 실행 → 온보딩 화면
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
            #if os(macOS)
            // macOS: 와이드(분할) 레이아웃이 항상 성립하도록 최소 윈도우 크기 지정
            .frame(minWidth: 1080, minHeight: 720)
            #endif
            // 앱 실행 시 배경음악 재생 시작 (설정에서 꺼져 있으면 내부적으로 무시됨)
            .onAppear { SoundService.shared.startBackgroundMusic() }
            // 홈 화면으로 나가면 일시정지, 돌아오면 재생 (onAppear는 최초 1회뿐이라 복귀 시 음악이 다시 안 나오던 문제)
            // 재생 시 설정 꺼짐·다른 앱 음악 재생 중 조건은 startBackgroundMusic이 그 순간 기준으로 판단
            // (맥은 다른 앱으로 전환해도 background가 되지 않아 기존처럼 계속 재생)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background: SoundService.shared.pauseBackgroundMusic()
                case .active:     SoundService.shared.startBackgroundMusic()
                default:          break
                }
            }
        }
        // ProgressService가 소유한 단일 컨테이너를 주입 (스토어 일원화)
        .modelContainer(ProgressService.shared.modelContainer)
        // 맥 기본 윈도우 크기 — 큰 화면 활용 (아이폰/아이패드에선 무시됨)
        .defaultSize(width: 1280, height: 860)
    }
}
