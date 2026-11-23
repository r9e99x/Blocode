//
//  CustomMapListViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation
import Observation

// MARK: - CustomMapListViewModel
/// 내 맵 목록 화면의 상태 — 저장된 맵을 화면에 보여 줄 한 줄 정보로 가공하고 삭제를 처리
/// 목록은 저장소(CustomMapService, @Observable)의 `maps`에서 바로 계산하므로, 저장·삭제하면 화면이 자동으로 갱신됨
@Observable
final class CustomMapListViewModel {

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

    private let service: CustomMapService

    init(service: CustomMapService? = nil) {
        self.service = service ?? .shared
    }

    /// 화면에 보여 줄 목록 — 저장소의 맵을 읽을 때마다 가공 (읽기 추적으로 저장·삭제가 바로 반영됨)
    /// shortcut: 화면이 다시 그려질 때마다 맵 JSON을 다시 풀어 씀, 내 맵이 수백 개로 늘어 목록이 버벅이면 maps가 바뀔 때만 다시 만드는 캐시로
    /// 저장된 맵이 바뀔 때만 다시 만듦 — 예전엔 화면을 그릴 때마다 모든 맵의 JSON을 디코딩했음
    var rows: [Row] {
        let maps = service.maps  // 관찰 대상 — 저장·삭제하면 화면이 다시 그려짐
        let key = maps.map { RowKey(id: $0.id, updatedAt: $0.updatedAt, name: $0.name, threeStar: $0.threeStar) }
        if key != cachedKey {
            cachedRows = maps.map { Self.makeRow($0) }  // 함수 이름을 그대로 넘기면 메인 액터 경고가 나서 클로저로 감쌈
            cachedKey = key
        }
        return cachedRows
    }

    /// 줄을 다시 만들지 판단하는 열쇠 — 맵을 고치면 수정 시각이 바뀌고, 화면에 보이는 이름·별 기준도 함께 비교해 확실히 함
    private struct RowKey: Equatable {
        let id: UUID
        let updatedAt: Date
        let name: String
        let threeStar: Int
    }
    @ObservationIgnored private var cachedKey: [RowKey] = []
    @ObservationIgnored private var cachedRows: [Row] = []

    var isEmpty: Bool { service.maps.isEmpty }

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
