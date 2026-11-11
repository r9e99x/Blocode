//
//  CustomMapService.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation
import Combine
import SwiftData
import os

// MARK: - CustomMapService
/// 사용자가 만든 맵을 저장·불러오는 서비스
/// 저장 전에 MapValidator로 깰 수 있는 맵인지 확인하므로, 저장된 맵은 항상 플레이할 수 있음
/// 진행도(ProgressService)와 같은 컨테이너를 쓰지만 기록은 서로 섞이지 않음 — 진행도 초기화에도 맵은 남음
final class CustomMapService: ObservableObject {

    /// 앱 전역에서 공유 — ProgressService가 소유한 단일 컨테이너를 사용
    static let shared = CustomMapService(container: ProgressService.shared.modelContainer)

    static let maxNameLength = 20

    /// 저장 실패 이유
    enum SaveError: LocalizedError, Equatable {
        case invalidName          // 이름이 비었거나 너무 김
        case invalidMap([String]) // 맵 검증 실패 — 사용자에게 보여 줄 문제 목록
        case invalidThresholds    // 별 기준이 올바르지 않음
        case storageFailed        // 저장소 오류

        var errorDescription: String? {
            switch self {
            case .invalidName: return "맵 이름은 1~\(CustomMapService.maxNameLength)자로 입력해 주세요."
            case .invalidMap(let issues): return issues.joined(separator: "\n")
            case .invalidThresholds: return "별 기준이 올바르지 않아요."
            case .storageFailed: return "맵을 저장하지 못했어요. 잠시 후 다시 시도해 주세요."
            }
        }
    }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Blocode",
                                category: "CustomMapService")

    /// 컨테이너를 함께 들고 있어야 컨텍스트가 유지됨
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// 저장된 맵 — 최근에 고친 순서
    @Published private(set) var maps: [CustomMap] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    // MARK: - 읽기

    /// 저장소에서 맵 목록을 다시 읽어 미러를 갱신
    func reload() {
        let descriptor = FetchDescriptor<CustomMap>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        maps = (try? context.fetch(descriptor)) ?? []
    }

    /// 번호로 맵 찾기
    func map(withID id: UUID) -> CustomMap? {
        maps.first { $0.id == id }
    }

    // MARK: - 쓰기

    /// 맵 저장 — id가 있고 저장된 맵이면 고치고, 아니면 새로 만듦
    /// - Throws: SaveError — 저장된 내용은 바뀌지 않음
    @discardableResult
    func save(id: UUID? = nil, name: String, map: MapData, palette: [BlockType],
              thresholds: StarThresholds) throws -> CustomMap {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...Self.maxNameLength).contains(trimmed.count) else { throw SaveError.invalidName }

        let validation = MapValidator.validate(map, palette: palette)
        guard validation.isValid else { throw SaveError.invalidMap(validation.issues) }

        guard thresholds.threeStar > 0, thresholds.threeStar <= thresholds.twoStar else {
            throw SaveError.invalidThresholds
        }

        let saved: CustomMap
        if let id, let existing = self.map(withID: id) {
            existing.update(name: trimmed, map: map, palette: palette, thresholds: thresholds)
            saved = existing
        } else {
            saved = CustomMap.make(name: trimmed, map: map, palette: palette, thresholds: thresholds)
            context.insert(saved)
        }

        do {
            try context.save()
        } catch {
            logger.error("맵 저장 실패: \(String(describing: error), privacy: .public)")
            context.rollback()
            reload()
            throw SaveError.storageFailed
        }
        reload()
        return saved
    }

    /// 맵 삭제
    func delete(_ map: CustomMap) {
        context.delete(map)
        do {
            try context.save()
        } catch {
            logger.error("맵 삭제 실패: \(String(describing: error), privacy: .public)")
            context.rollback()
        }
        reload()
    }
}
