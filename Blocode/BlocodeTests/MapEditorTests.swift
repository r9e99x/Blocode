//
//  MapEditorTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/11/26.
//
//  맵 에디터 ViewModel의 규칙 검증 — 칠하기, 요소 배치와 짝 맺기, 크기 변경,
//  팔레트, 되돌리기, 확인(검증)과 저장. 화면 없이 규칙만 확인한다.
//  기본 맵은 7×7, 가운데 줄(y=3)만 바닥이고 시작 (0,3) 오른쪽, 목표 (6,3).

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("맵 에디터")
struct MapEditorTests {

    private func at(_ x: Int, _ y: Int) -> Position { Position(x: x, y: y) }

    private func makeEditor(tool: MapEditorTool? = nil) -> MapEditorViewModel {
        let editor = MapEditorViewModel()
        if let tool { editor.selectTool(tool) }
        return editor
    }

    /// 메모리 저장소 서비스 — progress를 함께 돌려줘야 컨테이너가 유지됨
    private func makeService() -> (service: CustomMapService, progress: ProgressService) {
        let progress = ProgressService.makeForTesting()
        return (CustomMapService(container: progress.modelContainer), progress)
    }

    // MARK: - 기본 맵

    @Test("새 맵은 바로 저장할 수 있는 직선 맵")
    func defaultMapIsValid() {
        let editor = makeEditor()
        #expect(editor.width == 7 && editor.height == 7)
        let result = editor.validate()
        #expect(result.isValid)
        #expect(result.shortestSolution?.count == 6)
        #expect(editor.palette == [.moveForward, .turnLeft, .turnRight, .repeatBlock, .ifBlock])
        #expect(editor.thresholds?.threeStar == 6)
        #expect(editor.thresholds?.twoStar == 10)
    }

    // MARK: - 칠하기

    @Test("바닥과 벽 칠하기, 되돌리기로 복원")
    func paintFloorAndWall() {
        let editor = makeEditor(tool: .floor)
        #expect(editor.tap(at: at(2, 1)))
        #expect(editor.cell(at: at(2, 1)).isFloor)
        #expect(!editor.tap(at: at(2, 1)))  // 이미 바닥이면 변화 없음

        editor.selectTool(.wall)
        #expect(editor.tap(at: at(2, 1)))
        #expect(!editor.cell(at: at(2, 1)).isFloor)

        editor.undo()
        #expect(editor.cell(at: at(2, 1)).isFloor)
    }

    @Test("시작과 목표 칸은 벽으로 만들 수 없음")
    func wallRefusedOnStartAndGoal() {
        let editor = makeEditor(tool: .wall)
        #expect(!editor.tap(at: at(0, 3)))
        #expect(!editor.tap(at: at(6, 3)))
        #expect(editor.cell(at: at(0, 3)).isFloor)
        #expect(editor.message == "시작과 목표 칸은 벽으로 만들 수 없어요.")
    }

    @Test("범위 밖 칸은 무시")
    func outOfBounds() {
        let editor = makeEditor(tool: .floor)
        #expect(!editor.tap(at: at(-1, 0)))
        #expect(!editor.tap(at: at(7, 0)))
        #expect(!editor.canUndo)
    }

    // MARK: - 시작과 목표

    @Test("시작 옮기기와 방향 돌리기")
    func moveStartAndRotate() {
        let editor = makeEditor(tool: .start)
        #expect(editor.tap(at: at(1, 3)))
        #expect(editor.map.start == at(1, 3))
        #expect(editor.map.startDirection == .right)
        // 벽 칸에 놓으면 바닥이 됨
        #expect(editor.tap(at: at(1, 1)))
        #expect(editor.cell(at: at(1, 1)).isStart && editor.cell(at: at(1, 1)).isFloor)
        // 시작 칸을 다시 누르면 오른쪽으로 90도
        #expect(editor.tap(at: at(1, 1)))
        #expect(editor.map.startDirection == .down)
    }

    @Test("시작과 목표는 같은 칸에 둘 수 없음")
    func startAndGoalCannotOverlap() {
        let editor = makeEditor(tool: .start)
        #expect(!editor.tap(at: at(6, 3)))
        editor.selectTool(.goal)
        #expect(!editor.tap(at: at(0, 3)))
        #expect(editor.map.start == at(0, 3) && editor.map.goal == at(6, 3))
    }

    @Test("목표를 옮기면 그 칸의 보석은 사라짐")
    func goalReplacesItem() {
        let editor = makeEditor(tool: .item)
        editor.tap(at: at(3, 3))
        editor.selectTool(.goal)
        #expect(editor.tap(at: at(3, 3)))
        #expect(editor.map.goal == at(3, 3))
        #expect(editor.map.items == nil)
    }

    @Test("방향을 직접 지정")
    func setDirection() {
        let editor = makeEditor()
        editor.setStartDirection(.up)
        #expect(editor.map.startDirection == .up)
        editor.undo()
        #expect(editor.map.startDirection == .right)
    }

    // MARK: - 보석

    @Test("보석은 눌러서 놓고 다시 눌러서 지움, 놓으면 획득 블럭이 팔레트에 생김")
    func itemToggleAndPalette() {
        let editor = makeEditor(tool: .item)
        #expect(!editor.palette.contains(.collectItem))
        editor.tap(at: at(3, 3))
        #expect(editor.cell(at: at(3, 3)).hasItem)
        #expect(editor.palette.contains(.collectItem))
        editor.tap(at: at(3, 3))
        #expect(!editor.cell(at: at(3, 3)).hasItem)
        #expect(!editor.palette.contains(.collectItem))
    }

    @Test("보석은 목표 칸에 놓을 수 없고 개수 제한이 있음")
    func itemRules() {
        let editor = makeEditor(tool: .item)
        #expect(!editor.tap(at: at(6, 3)))
        #expect(editor.message == "목표 칸에는 보석을 놓을 수 없어요.")
        for x in 0..<MapValidator.maxItems { #expect(editor.tap(at: at(x, 1))) }
        #expect(!editor.tap(at: at(6, 1)))
        #expect(editor.map.items?.count == MapValidator.maxItems)
    }

    @Test("보석을 놓으면 그 칸의 포탈 짝은 사라짐")
    func itemReplacesPortal() {
        let editor = makeEditor(tool: .portal)
        editor.tap(at: at(1, 3))
        editor.tap(at: at(5, 3))
        #expect(editor.map.portals?.count == 1)
        editor.selectTool(.item)
        editor.tap(at: at(1, 3))
        #expect(editor.map.portals == nil)
        #expect(editor.cell(at: at(1, 3)).hasItem)
    }

    // MARK: - 스위치와 문

    @Test("스위치를 놓고 문을 놓으면 짝이 맺어짐")
    func switchGatePairing() {
        let editor = makeEditor(tool: .switchGate)
        #expect(editor.tap(at: at(1, 3)))
        #expect(editor.pending == .switchCell(at(1, 3)))
        #expect(editor.cell(at: at(1, 3)).isPending)
        #expect(editor.map.switches == nil)  // 짝이 완성되기 전엔 저장되지 않음

        #expect(editor.tap(at: at(1, 2)))
        #expect(editor.pending == nil)
        #expect(editor.map.switches?.count == 1)
        #expect(editor.cell(at: at(1, 3)).switchPair == 0)
        #expect(editor.cell(at: at(1, 2)).gatePair == 0)
        #expect(!editor.cell(at: at(1, 2)).isFloor)
        #expect(editor.palette.contains(.activateSwitch))
    }

    @Test("바닥 칸에 문을 놓으면 벽이 되고, 스위치를 밟아야 지나갈 수 있는 맵이 됨")
    func gateOnCorridor() {
        let editor = makeEditor(tool: .switchGate)
        editor.tap(at: at(1, 3))
        editor.tap(at: at(3, 3))
        #expect(!editor.cell(at: at(3, 3)).isFloor)
        let result = editor.validate()
        #expect(result.isValid)
        #expect(result.shortestSolution == [.moveForward, .activateSwitch, .moveForward, .moveForward,
                                            .moveForward, .moveForward, .moveForward])
    }

    @Test("문은 시작·목표·보석·다른 짝이 있는 칸에는 놓을 수 없음")
    func gateRefusedOnOccupied() {
        let editor = makeEditor(tool: .item)
        editor.tap(at: at(2, 3))
        editor.selectTool(.switchGate)
        editor.tap(at: at(1, 3))
        #expect(!editor.tap(at: at(0, 3)))   // 시작
        #expect(!editor.tap(at: at(6, 3)))   // 목표
        #expect(!editor.tap(at: at(2, 3)))   // 보석
        #expect(editor.pending == .switchCell(at(1, 3)))  // 거부돼도 짝 맺기는 계속
        #expect(editor.message == "문은 비어 있는 칸이나 벽 칸에만 놓을 수 있어요.")
    }

    @Test("놓은 스위치나 문을 다시 누르면 짝이 지워지고, 첫 칸을 다시 누르면 취소")
    func switchGateRemoveAndCancel() {
        let editor = makeEditor(tool: .switchGate)
        editor.tap(at: at(1, 3))
        editor.tap(at: at(1, 2))
        #expect(editor.tap(at: at(1, 2)))  // 문을 눌러 짝 지움
        #expect(editor.map.switches == nil)

        editor.tap(at: at(1, 3))
        editor.tap(at: at(1, 2))
        editor.tap(at: at(1, 3))           // 스위치를 눌러 짝 지움
        #expect(editor.map.switches == nil)

        editor.tap(at: at(2, 3))           // 새 스위치 → 대기
        #expect(editor.tap(at: at(2, 3)))  // 같은 칸 → 취소
        #expect(editor.pending == nil)
    }

    @Test("스위치는 목표 칸에 놓을 수 없고 개수 제한이 있음")
    func switchRules() {
        let editor = makeEditor(tool: .switchGate)
        #expect(!editor.tap(at: at(6, 3)))
        for index in 0..<MapValidator.maxSwitches {
            editor.tap(at: at(index, 3))     // 스위치
            editor.tap(at: at(index, 1))     // 문
        }
        #expect(editor.map.switches?.count == MapValidator.maxSwitches)
        #expect(!editor.tap(at: at(4, 3)))
        #expect(editor.pending == nil)
    }

    @Test("바닥을 칠하면 그 칸의 문이, 벽을 칠하면 그 칸의 스위치 짝이 사라짐")
    func paintRemovesPairs() {
        let editor = makeEditor(tool: .switchGate)
        editor.tap(at: at(1, 3))
        editor.tap(at: at(1, 2))
        editor.selectTool(.floor)
        editor.tap(at: at(1, 2))
        #expect(editor.map.switches == nil)

        editor.selectTool(.switchGate)
        editor.tap(at: at(1, 3))
        editor.tap(at: at(1, 2))
        editor.selectTool(.wall)
        editor.tap(at: at(1, 3))
        #expect(editor.map.switches == nil)
    }

    // MARK: - 포탈

    @Test("포탈 두 칸을 눌러 짝을 맺고, 다시 누르면 짝이 지워짐")
    func portalPairing() {
        let editor = makeEditor(tool: .portal)
        editor.tap(at: at(1, 1))
        #expect(editor.pending == .portalEnd(at(1, 1)))
        #expect(editor.cell(at: at(1, 1)).isFloor)  // 벽이던 칸도 바닥이 됨
        #expect(editor.map.portals == nil)

        editor.tap(at: at(5, 1))
        #expect(editor.pending == nil)
        #expect(editor.map.portals == [PortalPair(a: at(1, 1), b: at(5, 1))])
        #expect(editor.cell(at: at(5, 1)).portalPair == 0)

        #expect(editor.tap(at: at(5, 1)))
        #expect(editor.map.portals == nil)
    }

    @Test("포탈은 시작·목표·보석과 칸을 나눌 수 없고 첫 칸을 다시 누르면 취소")
    func portalRules() {
        let editor = makeEditor(tool: .portal)
        #expect(!editor.tap(at: at(0, 3)))
        #expect(editor.message == "포탈은 시작·목표·보석·스위치·문과 같은 칸에 놓을 수 없어요.")
        #expect(!editor.tap(at: at(6, 3)))
        editor.tap(at: at(1, 1))
        #expect(editor.tap(at: at(1, 1)))
        #expect(editor.pending == nil)
    }

    @Test("포탈은 4쌍까지")
    func portalLimit() {
        let editor = makeEditor(tool: .portal)
        for index in 0..<MapValidator.maxPortalPairs {
            editor.tap(at: at(index, 1))
            editor.tap(at: at(index, 5))
        }
        #expect(editor.map.portals?.count == MapValidator.maxPortalPairs)
        #expect(!editor.tap(at: at(5, 1)))
        #expect(editor.pending == nil)
    }

    @Test("포탈로 벽을 건너는 맵을 풀 수 있다고 확인")
    func portalMapSolvable() {
        let editor = makeEditor(tool: .wall)
        editor.tap(at: at(3, 3))  // 길을 막음
        editor.selectTool(.portal)
        editor.tap(at: at(2, 3))
        editor.tap(at: at(4, 3))
        #expect(editor.validate().isValid)
    }

    // MARK: - 지우개

    @Test("지우개는 보석·스위치 짝·포탈 짝을 지우고 시작과 목표는 지키며 바닥은 건드리지 않음")
    func eraser() {
        let editor = makeEditor(tool: .item)
        editor.tap(at: at(2, 3))
        editor.selectTool(.eraser)
        #expect(editor.tap(at: at(2, 3)))
        #expect(editor.map.items == nil)
        #expect(editor.cell(at: at(2, 3)).isFloor)
        #expect(!editor.tap(at: at(2, 3)))  // 지울 게 없음
        #expect(!editor.tap(at: at(0, 3)))
        #expect(!editor.tap(at: at(6, 3)))
        #expect(editor.message == "시작과 목표는 지울 수 없어요. 다른 칸에 놓아서 옮겨 주세요.")
    }

    // MARK: - 크기

    @Test("크기를 늘리면 새 칸은 벽, 기존 칸은 그대로")
    func resizeGrow() {
        let editor = makeEditor()
        #expect(editor.resize(width: 9, height: 8))
        #expect(editor.width == 9 && editor.height == 8)
        #expect(editor.cell(at: at(3, 3)).isFloor)
        #expect(!editor.cell(at: at(8, 7)).isFloor)
        #expect(editor.validate().isValid)
    }

    @Test("범위를 벗어난 크기와 시작·목표가 밖으로 나가는 축소는 거부")
    func resizeRefusals() {
        let editor = makeEditor()
        #expect(!editor.resize(width: 2, height: 7))
        #expect(!editor.resize(width: 7, height: 11))
        #expect(!editor.resize(width: 5, height: 7))  // 목표 (6,3)이 밖으로 나감
        #expect(editor.width == 7)
        #expect(editor.message == "시작이나 목표가 새 크기 밖에 있어요. 먼저 안쪽으로 옮겨 주세요.")
    }

    @Test("줄이면 밖으로 나간 요소는 지워지고 한 번에 되돌릴 수 있음")
    func resizeShrinkDropsElements() {
        let editor = makeEditor(tool: .goal)
        editor.tap(at: at(2, 3))
        editor.selectTool(.item)
        editor.tap(at: at(6, 1))
        editor.selectTool(.portal)
        editor.tap(at: at(1, 1))
        editor.tap(at: at(6, 5))
        #expect(editor.resize(width: 4, height: 7))
        #expect(editor.map.items == nil)
        #expect(editor.map.portals == nil)  // 한쪽이 밖이면 짝 전체가 사라짐
        editor.undo()
        #expect(editor.width == 7)
        #expect(editor.map.items?.count == 1)
        #expect(editor.map.portals?.count == 1)
    }

    // MARK: - 팔레트

    @Test("블럭 켜고 끄기, 기믹 블럭은 직접 바꿀 수 없음")
    func toggleBlocks() {
        let editor = makeEditor()
        editor.toggleBlock(.repeatBlock)
        #expect(!editor.palette.contains(.repeatBlock))
        editor.toggleBlock(.functionBlock)
        #expect(editor.palette.contains(.functionBlock))
        editor.toggleBlock(.collectItem)
        editor.toggleBlock(.activateSwitch)
        #expect(!editor.palette.contains(.collectItem) && !editor.palette.contains(.activateSwitch))
        editor.undo()  // 함수 켜기 취소
        #expect(!editor.palette.contains(.functionBlock))
    }

    @Test("팔레트가 맵을 못 풀게 만들면 확인에서 걸림")
    func paletteTooPoor() {
        let editor = makeEditor()
        editor.toggleBlock(.moveForward)
        #expect(editor.validate().issues == ["선택한 블럭으로는 목표에 도착할 수 없어요."])
    }

    // MARK: - 되돌리기

    @Test("끌어서 칠한 한 획은 되돌리기 한 단계")
    func strokeIsOneUndoStep() {
        let editor = makeEditor(tool: .floor)
        editor.beginStroke()
        for x in 1...3 { editor.paint(at: at(x, 1)) }
        editor.endStroke()
        #expect((1...3).allSatisfy { editor.cell(at: at($0, 1)).isFloor })
        editor.undo()
        #expect((1...3).allSatisfy { !editor.cell(at: at($0, 1)).isFloor })
        #expect(!editor.canUndo)
        #expect(editor.canRedo)
        editor.redo()
        #expect((1...3).allSatisfy { editor.cell(at: at($0, 1)).isFloor })
    }

    @Test("바뀐 게 없는 누름은 되돌리기에 쌓이지 않고, 새 수정은 다시 하기를 지움")
    func historyRules() {
        let editor = makeEditor(tool: .floor)
        editor.tap(at: at(3, 3))  // 이미 바닥
        #expect(!editor.canUndo)
        editor.tap(at: at(1, 1))
        editor.undo()
        #expect(editor.canRedo)
        editor.tap(at: at(2, 1))
        #expect(!editor.canRedo)
    }

    @Test("되돌리기는 50단계까지")
    func historyLimit() {
        let editor = makeEditor(tool: .floor)
        for index in 0..<60 { editor.tap(at: at(index % 7, index % 3)) }
        var steps = 0
        while editor.canUndo {
            editor.undo()
            steps += 1
        }
        #expect(steps <= 50)
    }

    @Test("도구를 바꾸면 짝 맺던 것은 취소")
    func selectToolCancelsPending() {
        let editor = makeEditor(tool: .portal)
        editor.tap(at: at(1, 1))
        #expect(editor.pending != nil)
        editor.selectTool(.floor)
        #expect(editor.pending == nil)
    }

    @Test("다음 누름에서 안내 문구가 지워짐")
    func messageClears() {
        let editor = makeEditor(tool: .wall)
        editor.tap(at: at(0, 3))
        #expect(editor.message != nil)
        editor.tap(at: at(2, 1))
        #expect(editor.message == nil)
    }

    // MARK: - 확인 결과와 별 기준

    @Test("맵을 고치면 확인 결과가 사라짐")
    func editInvalidatesValidation() {
        let editor = makeEditor(tool: .floor)
        editor.validate()
        #expect(editor.validation != nil)
        editor.tap(at: at(1, 1))
        #expect(editor.validation == nil)
        #expect(editor.thresholds == nil)
        #expect(editor.previewStage == nil)
    }

    @Test("테스트 플레이로 더 적게 깨면 별 3개 기준이 내려가고, 고치면 사라짐")
    func testClearLowersThreshold() {
        let editor = makeEditor(tool: .floor)
        editor.recordTestClear(blockCount: 3)  // 확인 전에는 무시
        #expect(editor.testClearBlockCount == nil)

        editor.validate()
        editor.recordTestClear(blockCount: 3)
        editor.recordTestClear(blockCount: 5)  // 더 많은 기록은 무시
        #expect(editor.testClearBlockCount == 3)
        #expect(editor.thresholds?.threeStar == 3)
        #expect(editor.thresholds?.twoStar == 7)

        editor.recordTestClear(blockCount: 99)  // 최단 풀이보다 많으면 기준은 최단 그대로
        editor.tap(at: at(1, 1))
        #expect(editor.testClearBlockCount == nil)
    }

    @Test("확인을 통과하면 테스트 플레이용 스테이지가 만들어짐")
    func previewStage() {
        let editor = makeEditor()
        editor.name = "내 맵"
        #expect(editor.previewStage == nil)
        editor.validate()
        let stage = editor.previewStage
        #expect(stage?.name == "내 맵")
        #expect(stage?.paletteBlocks == editor.palette)
        #expect(stage?.starThresholds.threeStar == 6)
        #expect(stage?.chapter == 0)
    }

    // MARK: - 저장

    @Test("저장하면 서비스에 생기고 같은 에디터로 다시 저장하면 고침")
    func saveCreatesThenUpdates() throws {
        let (service, progress) = makeService()
        let editor = makeEditor()
        editor.name = "첫 맵"
        editor.tap(at: at(1, 1))  // 수정 표시
        #expect(editor.isDirty)

        let saved = try editor.save(to: service)
        #expect(service.maps.count == 1)
        #expect(editor.editingID == saved.id)
        #expect(!editor.isDirty)

        editor.name = "고친 맵"
        let again = try editor.save(to: service)
        #expect(again.id == saved.id)
        #expect(service.maps.count == 1)
        #expect(service.maps.first?.name == "고친 맵")
        _ = progress
    }

    @Test("이름이 없거나 풀 수 없는 맵은 저장되지 않음")
    func saveRejections() {
        let (service, progress) = makeService()
        let editor = makeEditor()
        #expect(throws: CustomMapService.SaveError.invalidName) { try editor.save(to: service) }

        editor.name = "막힌 맵"
        editor.selectTool(.wall)
        editor.tap(at: at(3, 3))
        #expect(throws: CustomMapService.SaveError.invalidMap(["선택한 블럭으로는 목표에 도착할 수 없어요."])) {
            try editor.save(to: service)
        }
        #expect(service.maps.isEmpty)
        _ = progress
    }

    @Test("짝을 기다리던 칸은 저장되지 않음")
    func pendingNotSaved() throws {
        let (service, progress) = makeService()
        let editor = makeEditor(tool: .portal)
        editor.name = "대기 맵"
        editor.tap(at: at(1, 1))  // 짝이 없는 포탈 한 칸
        let saved = try editor.save(to: service)
        #expect(saved.mapData?.portals == nil)
        _ = progress
    }

    @Test("저장된 맵을 불러와 고칠 수 있고 기믹 블럭은 팔레트 선택에서 빠짐")
    func editExistingMap() throws {
        let (service, progress) = makeService()
        let editor = makeEditor(tool: .item)
        editor.name = "보석 맵"
        editor.tap(at: at(2, 3))
        let saved = try editor.save(to: service)
        #expect(saved.palette.contains(.collectItem))

        let reopened = try #require(MapEditorViewModel(editing: saved))
        #expect(reopened.name == "보석 맵")
        #expect(reopened.editingID == saved.id)
        #expect(reopened.map.items == [at(2, 3)])
        #expect(!reopened.enabledBlocks.contains(.collectItem))
        #expect(reopened.palette.contains(.collectItem))  // 보석이 있으니 자동으로 들어감
        #expect(!reopened.isDirty)
        _ = progress
    }

    @Test("손상된 맵은 에디터로 열 수 없음")
    func corruptedMapCannotOpen() {
        let broken = CustomMap(name: "깨진 맵", mapJSON: Data("x".utf8), paletteRaw: [], threeStar: 1, twoStar: 5)
        #expect(MapEditorViewModel(editing: broken) == nil)
    }
}

// MARK: - 격자 좌표 계산

@Suite("에디터 격자 좌표")
struct EditorGridLayoutTests {

    @Test("터치 좌표를 칸으로 바꾸고 격자 밖은 nil")
    func positionAtPoint() {
        let layout = EditorGridLayout(size: CGSize(width: 400, height: 400), cols: 7, rows: 7)
        for position in [Position(x: 0, y: 0), Position(x: 3, y: 2), Position(x: 6, y: 6)] {
            let rect = layout.rect(of: position)
            #expect(layout.position(at: CGPoint(x: rect.midX, y: rect.midY)) == position)
        }
        #expect(layout.position(at: CGPoint(x: 2, y: 200)) == nil)     // 왼쪽 여백
        #expect(layout.position(at: CGPoint(x: 200, y: 398)) == nil)   // 아래 여백
        #expect(layout.position(at: CGPoint(x: -5, y: -5)) == nil)
    }

    @Test("가로세로가 다른 맵은 짧은 쪽에 맞춰 가운데 정렬")
    func nonSquareMapIsCentered() {
        let layout = EditorGridLayout(size: CGSize(width: 300, height: 600), cols: 5, rows: 9)
        #expect(abs(layout.cell - 55.2) < 0.01)   // 가로 기준 (300 - 24) / 5
        let first = layout.rect(of: Position(x: 0, y: 0))
        let last = layout.rect(of: Position(x: 4, y: 8))
        #expect(abs(first.minX - (300 - last.maxX)) < 0.01)   // 좌우 여백이 같음
        #expect(abs(first.minY - (600 - last.maxY)) < 0.01)   // 위아래 여백이 같음
    }

    @Test("끌기 중 건너뛴 칸을 이어 줌")
    func cellsBetween() {
        #expect(EditorGridLayout.cells(from: Position(x: 0, y: 0), to: Position(x: 4, y: 0))
                == [1, 2, 3, 4].map { Position(x: $0, y: 0) })
        #expect(EditorGridLayout.cells(from: Position(x: 2, y: 2), to: Position(x: 2, y: 2)) == [Position(x: 2, y: 2)])
        #expect(EditorGridLayout.cells(from: Position(x: 0, y: 0), to: Position(x: 3, y: 3))
                == [Position(x: 1, y: 1), Position(x: 2, y: 2), Position(x: 3, y: 3)])
        #expect(EditorGridLayout.cells(from: Position(x: 3, y: 1), to: Position(x: 1, y: 1))
                == [Position(x: 2, y: 1), Position(x: 1, y: 1)])
    }
}
