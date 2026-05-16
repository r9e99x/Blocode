//
//  ProgressService.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import Combine

// MARK: - StageResult
/// 스테이지 하나의 클리어 기록 — UserDefaults에 JSON으로 저장
struct StageResult: Codable {
    var isCleared: Bool       // 클리어 여부
    var stars: Int            // 획득 별 수 0~3
    var bestBlockCount: Int   // 지금까지 사용한 최소 블럭 수
}

// MARK: - ProgressService
/// 스테이지 클리어 기록을 UserDefaults에 저장/불러오는 서비스
/// 앱 전역에서 @EnvironmentObject 로 주입하여 사용
final class ProgressService: ObservableObject {

    // MARK: 싱글톤
    static let shared = ProgressService()

    // MARK: Published — 뷰가 감지하는 진행도 딕셔너리
    /// key: stageId (예: "ch1_stage1"), value: StageResult
    @Published private(set) var results: [String: StageResult] = [:]

    // UserDefaults 저장 키
    private let userDefaultsKey = "blocode_stage_results"

    // MARK: 초기화

    /// 초기화 시 UserDefaults에서 저장된 진행도 로드
    init() {
        load()
    }

    // MARK: - 읽기

    /// 특정 스테이지의 클리어 기록 반환 (없으면 nil)
    func result(for stageId: String) -> StageResult? {
        results[stageId]
    }

    /// 특정 스테이지가 클리어됐는지 여부 반환 (기록 없으면 false)
    func isCleared(_ stageId: String) -> Bool {
        results[stageId]?.isCleared ?? false
    }

    /// 특정 스테이지의 현재 별점 반환 (0~3, 기록 없으면 0)
    func stars(for stageId: String) -> Int {
        results[stageId]?.stars ?? 0
    }

    /// 특정 챕터의 총 획득 별점 합산
    /// - Parameters:
    ///   - chapter: 챕터 번호
    ///   - stageCount: 챕터 내 스테이지 총 개수
    func totalStars(chapter: Int, stageCount: Int) -> Int {
        guard stageCount > 0 else { return 0 }
        // 1번부터 stageCount까지 각 스테이지 별점 합산
        return (1...stageCount).reduce(0) { total, stageNum in
            total + stars(for: "ch\(chapter)_stage\(stageNum)")
        }
    }

    // MARK: - 잠금 조건

    /// 스테이지 잠금 여부 확인 (false = 플레이 가능)
    func isLocked(chapter: Int, stageNumber: Int) -> Bool {
        // 1스테이지는 항상 개방
        if stageNumber == 1 { return false }

        // Stage 6 (챕터 1 마지막): 1~5스테이지 별점 합산 9개 이상 필요
        if chapter == 1 && stageNumber == 6 {
            return totalStars(chapter: 1, stageCount: 5) < 9
        }

        // 그 외: 이전 스테이지 클리어 필요
        let prevId = "ch\(chapter)_stage\(stageNumber - 1)"
        return !isCleared(prevId)
    }

    // MARK: - 쓰기

    /// 스테이지 클리어 기록 저장 (별점/블럭수가 기존보다 좋을 때만 갱신)
    func recordClear(stageId: String, stars: Int, blockCount: Int) {
        let existing = results[stageId]
        // 블럭 수는 더 적은 값(최솟값)으로 갱신
        let newBest = min(blockCount, existing?.bestBlockCount ?? blockCount)
        // 별점은 더 높은 값(최댓값)으로 갱신
        let newStars = max(stars, existing?.stars ?? 0)

        results[stageId] = StageResult(
            isCleared: true,
            stars: newStars,
            bestBlockCount: newBest
        )
        // 변경 사항 UserDefaults에 저장
        save()
    }

    // MARK: - UserDefaults 영속성

    /// 현재 results를 JSON으로 인코딩하여 UserDefaults에 저장
    private func save() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    /// UserDefaults에서 JSON 데이터를 읽어 results로 복원
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([String: StageResult].self, from: data) else {
            return
        }
        results = saved
    }

    // MARK: - 개발용 리셋 (테스트 편의)
    /// 모든 진행도 초기화 — UserDefaults에서도 삭제
    func resetAll() {
        results = [:]
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
