//
//  StageProgress.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import SwiftData

// MARK: - StageProgress
/// 유저의 스테이지 진행 상황을 저장하는 SwiftData 모델 (진행도의 원본 = source of truth)
/// ProgressService가 이 모델을 읽고 쓰며, 뷰에는 StageResult 미러로 전달함.
/// 앱이 종료되어도 유지되며, Apple Developer 등록 후 iCloud(CloudKit) 동기화 연동 예정.
///
/// 참고 — 커스텀 맵/블럭(유저 제작 콘텐츠)은 추후 구현 예정:
///   기본 스테이지는 계속 JSON(Resources/Stages)으로 관리하고,
///   유저가 만든 커스텀 맵은 별도의 @Model(예: CustomMap)을 새로 추가해
///   동일한 ModelContainer 스키마에 등록하는 방식으로 확장할 것.
@Model
final class StageProgress {
    /// 스테이지 고유 ID (예: "ch1_stage1") — ProgressService와 동일한 키 형식 사용
    var stageId: String

    /// 클리어 여부 — true이면 해당 스테이지를 한 번 이상 완료한 상태
    var isCleared: Bool

    /// 획득한 별 수 (0~3) — 0은 미클리어, 1~3은 클리어 후 블럭 수 기준
    var stars: Int

    /// 지금까지 사용한 블럭 수 최소 기록 — 별점 계산의 기준값
    var bestBlockCount: Int

    /// 마지막으로 플레이한 날짜 — 진행 통계에 활용 예정
    var lastPlayedAt: Date

    // MARK: - 초기화
    /// 새 스테이지 진행 기록 생성 (모든 값 초기 상태로 설정)
    init(stageId: String) {
        self.stageId = stageId
        self.isCleared = false       // 미클리어 상태
        self.stars = 0               // 별 없음
        self.bestBlockCount = 0      // 블럭 기록 없음
        self.lastPlayedAt = Date()   // 현재 시각으로 초기화
    }

    // MARK: - 업데이트
    /// 클리어 결과로 진행 상황 업데이트 (더 좋은 기록이면 갱신)
    /// - Parameters:
    ///   - newStars: 이번 클리어에서 획득한 별 수
    ///   - blockCount: 이번 클리어에서 사용한 블럭 수
    func update(stars newStars: Int, blockCount: Int) {
        isCleared = true           // 클리어 완료 표시
        lastPlayedAt = Date()      // 마지막 플레이 시각 갱신

        // 더 많은 별을 획득했을 때만 갱신 (이미 높은 별점 보호)
        if newStars > stars {
            stars = newStars
        }

        // 최솟값 기록 갱신 (처음 클리어이거나 더 적은 블럭을 사용했을 때)
        if bestBlockCount == 0 || blockCount < bestBlockCount {
            bestBlockCount = blockCount
        }
    }
}
