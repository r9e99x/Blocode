//
//  StageDataIntegrityTests.swift
//  BlocodeTests
//
//  실제로 앱에 번들된 69개 스테이지 JSON(챕터 1~10)이 전부 파싱되고,
//  구조적으로 말이 되는지(격자 안의 시작/목표, 별점 기준 순서, 팔레트 등)를 검증.
//  이 테스트가 실패한다면 스테이지 JSON을 고치다가 뭔가 깨졌다는 뜻.

import Testing
@testable import Blocode

@Suite("스테이지 JSON 데이터 무결성")
struct StageDataIntegrityTests {

    /// (챕터 번호, 스테이지 수) 목록 — ChapterCatalog가 아닌 여기 하드코딩한 이유는
    /// "챕터 정의 자체가 실수로 잘못돼도" 스테이지 개수를 독립적으로 교차 검증하기 위함
    private var expectedStageCounts: [Int: Int] {
        [1: 6, 2: 8, 3: 8, 4: 7, 5: 6, 6: 7, 7: 7, 8: 7, 9: 7, 10: 6]
    }

    @Test("모든 챕터의 스테이지가 전부 로드됨")
    func everyChapter_allStagesLoadSuccessfully() {
        for (chapter, count) in expectedStageCounts.sorted(by: { $0.key < $1.key }) {
            let stages = StageLoader.loadChapter(chapter, stageCount: count)
            #expect(
                stages.count == count,
                "챕터 \(chapter)은 \(count)개 스테이지가 있어야 하는데 \(stages.count)개만 로드됨 — JSON 파일 누락/파싱 실패 의심"
            )
        }
    }

    @Test("모든 스테이지의 맵이 구조적으로 유효함")
    func everyStage_hasStructurallyValidMap() {
        for (chapter, count) in expectedStageCounts.sorted(by: { $0.key < $1.key }) {
            for stageNumber in 1...count {
                guard let stage = StageLoader.load(chapter: chapter, stage: stageNumber) else {
                    Issue.record("ch\(chapter)_stage\(stageNumber) 로드 실패")
                    continue
                }
                let map = stage.mapData
                let label = stage.id

                // 격자 자체가 비어있지 않아야 함 (온-패스 직선 튜토리얼 스테이지는 5x5보다 작을 수 있어
                // "최소 5x5" 같은 특정 크기는 강제하지 않음 — 실제로 6x1, 10x1 같은 스테이지도 존재함)
                #expect(map.width > 0, "\(label): 가로 크기가 0")
                #expect(map.height > 0, "\(label): 세로 크기가 0")

                // 시작/목표 지점이 실제로 맵 범위 안의 바닥 타일이어야 함
                #expect(map.isInBounds(map.start), "\(label): 시작 위치가 맵 범위 밖")
                #expect(map.isInBounds(map.goal),  "\(label): 목표 위치가 맵 범위 밖")
                #expect(map.isFloor(map.start), "\(label): 시작 위치가 바닥 타일이 아님")
                #expect(map.isFloor(map.goal),  "\(label): 목표 위치가 바닥 타일이 아님")

                // 시작 ≠ 목표 (이중 나선 등에서 실제로 한 번 발생했던 버그 — 재발 방지 회귀 테스트)
                #expect(map.start != map.goal, "\(label): 시작과 목표가 같은 칸 — 스테이지가 성립하지 않음")

                // 별점 기준: threeStar ≤ twoStar, 둘 다 양수
                #expect(stage.starThresholds.threeStar > 0, "\(label): threeStar 기준이 0 이하")
                #expect(
                    stage.starThresholds.threeStar <= stage.starThresholds.twoStar,
                    "\(label): threeStar 기준이 twoStar보다 큼(별 3개가 별 2개보다 조건이 헐거움)"
                )

                // 팔레트가 비어있으면 안 됨(적어도 하나의 블럭은 써야 클리어 가능)
                #expect(!stage.paletteBlocks.isEmpty, "\(label): 팔레트에 사용 가능한 블럭이 없음")

                // id가 파일명 규칙(ch{N}_stage{M})과 챕터/스테이지 번호 필드가 서로 일치해야 함
                #expect(stage.id == "ch\(chapter)_stage\(stageNumber)", "\(label): id가 파일명 규칙과 불일치")
                #expect(stage.chapter == chapter, "\(label): chapter 필드 불일치")
                #expect(stage.stageNumber == stageNumber, "\(label): stageNumber 필드 불일치")
            }
        }
    }

    /// collectItem/activateSwitch 블럭이 팔레트에 있다면, 그 기믹 데이터(items/switches)도 실제로 존재해야 함
    /// (반대로 기믹 데이터가 있는데 팔레트에 관련 블럭이 없으면 그 기믹은 절대 쓸 수 없는 죽은 데이터)
    @Test("팔레트의 기믹 블럭과 실제 기믹 데이터가 일치함")
    func gimmickBlocksInPalette_matchGimmickDataPresence() {
        for (chapter, count) in expectedStageCounts.sorted(by: { $0.key < $1.key }) {
            for stageNumber in 1...count {
                guard let stage = StageLoader.load(chapter: chapter, stage: stageNumber) else { continue }
                let label = stage.id
                let palette = Set(stage.paletteBlocks)

                if palette.contains(.collectItem) {
                    #expect(
                        !(stage.mapData.items?.isEmpty ?? true),
                        "\(label): collectItem 블럭은 있는데 items가 비어있음"
                    )
                }
                if palette.contains(.activateSwitch) {
                    #expect(
                        !(stage.mapData.switches?.isEmpty ?? true),
                        "\(label): activateSwitch 블럭은 있는데 switches가 비어있음"
                    )
                }
            }
        }
    }

    /// 스위치의 gateAt 위치는 원본 grid에서 반드시 벽(0)이어야 함(열리기 전 통행 불가 규칙)
    /// 그리고 switchAt은 반드시 바닥(1)이어야 함(밟고 지나갈 수 있어야 하므로)
    @Test("스위치-문 쌍의 원본 타일 종류가 올바름")
    func switchGatePairs_haveCorrectTileTypesInRawGrid() {
        for (chapter, count) in expectedStageCounts.sorted(by: { $0.key < $1.key }) {
            for stageNumber in 1...count {
                guard let stage = StageLoader.load(chapter: chapter, stage: stageNumber),
                      let switches = stage.mapData.switches, !switches.isEmpty else { continue }
                let label = stage.id
                let grid = stage.mapData.grid

                for pair in switches {
                    #expect(
                        grid[pair.switchAt.y][pair.switchAt.x] == TileType.floor.rawValue,
                        "\(label): 스위치 위치가 바닥이 아님 \(pair.switchAt)"
                    )
                    #expect(
                        grid[pair.gateAt.y][pair.gateAt.x] == TileType.wall.rawValue,
                        "\(label): 문 위치가 벽이 아님(열리기 전엔 벽이어야 함) \(pair.gateAt)"
                    )
                }
            }
        }
    }
}
