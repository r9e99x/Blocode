//
//  CustomMap.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation
import SwiftData

// MARK: - CustomMap
/// 사용자가 만든 맵을 저장하는 SwiftData 모델 (기본 스테이지는 계속 JSON으로 관리)
/// 맵 데이터는 MapData를 JSON으로 담아 두어, 나중에 맵 공유(파일·CloudKit)에 그대로 쓸 수 있게 함
/// CloudKit 동기화를 대비해 모든 속성에 기본값을 두고 유니크 제약은 걸지 않음
@Model
final class CustomMap {

    /// 스테이지 ID 접두사 — 기본 스테이지 ID(ch1_stage1)와 겹치지 않고 진행도 키와도 구분됨
    static let stageIDPrefix = "custom_"

    /// 맵 고유 번호
    var id: UUID = UUID()

    /// 맵 이름
    var name: String = ""

    /// MapData를 JSON으로 인코딩한 값
    var mapJSON: Data = Data()

    /// 팔레트 블럭 종류 (BlockType rawValue 목록)
    var paletteRaw: [String] = []

    /// 별 3개 기준 블럭 수
    var threeStar: Int = 1

    /// 별 2개 기준 블럭 수
    var twoStar: Int = 1

    /// 만든 시각
    var createdAt: Date = Date()

    /// 마지막으로 고친 시각 — 목록 정렬 기준
    var updatedAt: Date = Date()

    /// 저장 형식 버전 — 형식이 바뀌면 올려서 옛 데이터를 변환할 수 있게 함
    var formatVersion: Int = 1

    // MARK: - 초기화

    /// 저장된 값으로 직접 만드는 기본 초기화 — 맵 데이터를 인코딩하는 make를 주로 사용
    init(name: String, mapJSON: Data, paletteRaw: [String], threeStar: Int, twoStar: Int) {
        self.name = name
        self.mapJSON = mapJSON
        self.paletteRaw = paletteRaw
        self.threeStar = threeStar
        self.twoStar = twoStar
    }

    /// 맵 데이터를 JSON으로 인코딩해 새 맵을 만듦
    @MainActor
    static func make(name: String, map: MapData, palette: [BlockType], thresholds: StarThresholds) -> CustomMap {
        CustomMap(name: name, mapJSON: encode(map), paletteRaw: palette.map(\.rawValue),
                  threeStar: thresholds.threeStar, twoStar: thresholds.twoStar)
    }

    /// 내용을 새 값으로 교체 — id와 만든 시각은 유지
    @MainActor
    func update(name: String, map: MapData, palette: [BlockType], thresholds: StarThresholds) {
        self.name = name
        mapJSON = Self.encode(map)
        paletteRaw = palette.map(\.rawValue)
        threeStar = thresholds.threeStar
        twoStar = thresholds.twoStar
        updatedAt = Date()
    }

    @MainActor
    private static func encode(_ map: MapData) -> Data {
        (try? JSONEncoder().encode(map)) ?? Data()
    }

    // MARK: - 읽기

    /// 게임 진행 기록에서 이 맵을 가리키는 ID
    var stageID: String { Self.stageIDPrefix + id.uuidString }

    /// 저장된 맵 데이터 — 손상됐으면 nil
    @MainActor
    var mapData: MapData? { try? JSONDecoder().decode(MapData.self, from: mapJSON) }

    /// 팔레트 블럭 목록
    var palette: [BlockType] { paletteRaw.compactMap(BlockType.init(rawValue:)) }

    /// 게임 화면에 넣을 스테이지 — 손상됐으면 nil (챕터·번호는 기본 스테이지 전용이라 0)
    @MainActor
    var stage: Stage? {
        guard let map = mapData else { return nil }
        return Stage(id: stageID, chapter: 0, stageNumber: 0, name: name, mapData: map,
                     starThresholds: StarThresholds(threeStar: threeStar, twoStar: twoStar),
                     availableBlocks: palette)
    }
}
