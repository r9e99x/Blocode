//
//  CustomMapListViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation
import Combine

// MARK: - CustomMapListViewModel
/// 내 맵 목록 화면의 상태 — 저장된 맵을 화면에 보여 줄 한 줄 정보로 가공하고 삭제를 처리
/// 저장소(CustomMapService)가 바뀌면 목록이 자동으로 갱신됨
final class CustomMapListViewModel: ObservableObject {

    /// 목록 한 줄
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let map: MapData?          // 썸네일용 — 손상된 맵이면 nil
        let sizeText: String       // 예: "7×7"
        let elementsText: String   // 예: "보석 2 · 스위치 1 · 포탈 1"
        let starText: String       // 예: "별 3개 7블럭 이하"
        let updatedAt: Date

        /// 플레이할 수 있는 맵인지 — 손상된 맵은 삭제만 가능
        var isPlayable: Bool { map != nil }
    }

    @Published private(set) var rows: [Row] = []

    private let service: CustomMapService
    private var cancellable: AnyCancellable?

    @MainActor
    init(service: CustomMapService? = nil) {
        let service = service ?? .shared
        self.service = service
        rows = service.maps.map(Self.makeRow)
        cancellable = service.$maps
            .dropFirst()
            .sink { [weak self] maps in
                // 저장소는 메인 스레드에서만 바뀜
                MainActor.assumeIsolated { self?.rows = maps.map(Self.makeRow) }
            }
    }

    var isEmpty: Bool { rows.isEmpty }

    /// 번호로 저장된 맵 찾기 — 플레이·수정 화면이 사용
    func map(withID id: UUID) -> CustomMap? {
        service.map(withID: id)
    }

    func delete(id: UUID) {
        guard let map = service.map(withID: id) else { return }
        service.delete(map)
    }

    // MARK: - 가공

    private static func makeRow(_ saved: CustomMap) -> Row {
        let map = saved.mapData
        let sizeText = map.map { "\($0.width)×\($0.height)" } ?? "손상된 맵"
        return Row(id: saved.id,
                   name: saved.name,
                   map: map,
                   sizeText: sizeText,
                   elementsText: map.map(elementsSummary) ?? "열 수 없어요",
                   starText: "별 3개 \(saved.threeStar)블럭 이하",
                   updatedAt: saved.updatedAt)
    }

    /// 맵에 놓인 요소 요약 — 요소가 없으면 "기본 맵"
    nonisolated private static func elementsSummary(_ map: MapData) -> String {
        var parts: [String] = []
        if let count = map.items?.count, count > 0 { parts.append("보석 \(count)") }
        if let count = map.switches?.count, count > 0 { parts.append("스위치 \(count)") }
        if let count = map.portals?.count, count > 0 { parts.append("포탈 \(count)") }
        return parts.isEmpty ? "기본 맵" : parts.joined(separator: " · ")
    }
}
