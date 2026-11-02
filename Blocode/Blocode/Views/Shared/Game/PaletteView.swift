//
//  PaletteView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI
#if os(iOS)
import UIKit.UIGestureRecognizerSubclass  // 인식기 서브클래스에서 state를 바꾸려면 필요
#endif

// MARK: - PaletteView
/// 사용 가능한 블럭 타입을 가로 스크롤로 나열하는 팔레트 뷰
/// 탭으로 블럭 추가, 롱프레스 + 드래그로 위치 지정 삽입 지원
struct PaletteView: View {

    /// 이 스테이지에서 표시할 블럭 타입 목록 — Stage.availableBlocks에서 전달
    let availableBlocks: [BlockType]

    /// 블럭 탭 선택 콜백 — 선택된 BlockType을 전달
    let onSelect: (BlockType) -> Void

    /// 드래그 시작 콜백 — 타입과 글로벌 좌표 전달 (nil이면 드래그 비활성)
    var onDragStart:  ((BlockType, CGPoint) -> Void)? = nil
    /// 드래그 중 위치 변경 콜백
    var onDragChange: ((BlockType, CGPoint) -> Void)? = nil
    /// 드래그 종료 콜백 — 최종 위치 전달
    var onDragEnd:    ((BlockType, CGPoint) -> Void)? = nil

    // 팔레트 세로 크기 축소(iOS 전용) — 맥은 카드가 이미 작아서 기존 패딩 그대로 유지
    #if os(macOS)
    private let verticalPadding: CGFloat = 12
    #else
    private let verticalPadding: CGFloat = 9
    #endif

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 스테이지별 허용 블럭만 가로로 나열 (availableBlocks 기준)
                ForEach(availableBlocks, id: \.self) { type in
                    PaletteCardView(
                        type: type,
                        onTap:        { onSelect(type) },
                        // 드래그 콜백이 있을 때만 전달 (없으면 nil)
                        onDragStart:  onDragStart  != nil ? { pt in onDragStart?(type, pt)  } : nil,
                        onDragChange: onDragChange != nil ? { pt in onDragChange?(type, pt) } : nil,
                        onDragEnd:    onDragEnd    != nil ? { pt in onDragEnd?(type, pt)    } : nil
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, verticalPadding)
        }
        .background(Color.statCardBackground)  // 팔레트 컨테이너 — 홈 통계 카드와 같은 크림/미드 남색
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

// MARK: - PaletteCardView (3D)
/// 팔레트의 개별 블럭 카드 — 3D 버튼 스타일 + 탭/롱프레스-드래그 제스처
struct PaletteCardView: View {

    let type: BlockType             // 표시할 블럭 타입
    let onTap:        () -> Void    // 탭 콜백 (블럭 추가)
    var onDragStart:  ((CGPoint) -> Void)? = nil   // 드래그 시작 콜백
    var onDragChange: ((CGPoint) -> Void)? = nil   // 드래그 위치 변경 콜백
    var onDragEnd:    ((CGPoint) -> Void)? = nil   // 드래그 종료 콜백

    @State private var isPressed     = false  // 눌린 상태 (시각적 피드백)
    @State private var isDragging    = false  // 드래그 중 상태
    #if os(macOS)
    @State private var longPressTimer: Timer? = nil  // 롱프레스 감지 타이머
    #endif

    /// 드래그 활성화 여부 — onDragStart 콜백이 있을 때만 활성화
    private var dragEnabled: Bool { onDragStart != nil }

    // 3D 카드 파라미터 — 맥은 코드 패널 폭이 좁아 카드도 축소, iOS/아이패드는 기존 크기 유지
    #if os(macOS)
    private let btnSize:   CGFloat = 36
    private let radius:    CGFloat = 11
    private let topDepth:  CGFloat = 1.3
    private let botDepth:  CGFloat = 2.1
    #else
    private let btnSize:   CGFloat = 46   // 버튼 크기 (팔레트 세로 크기 축소 — 기존 54)
    private let radius:    CGFloat = 14   // 모서리 반지름
    private let topDepth:  CGFloat = 1.6  // 위 뒷면 두께
    private let botDepth:  CGFloat = 2.8  // 아래 뒷면 두께
    #endif

    // 아이콘 크기 — iOS는 버튼 축소에 맞춰 함께 축소, 맥은 기존 값 그대로 유지
    #if os(macOS)
    private let iconSize: CGFloat = 18
    #else
    private let iconSize: CGFloat = 16
    #endif

    var body: some View {
        // 3D 카드 — 공용 Bevel3DButtonLabel (위 뒷면 blockColor + white 0.28 / 아래 뒷면 blockColor + black 0.25 / 앞면 + 아이콘)
        // 눌림은 3D 내려앉기 대신 아래 scaleEffect로 표현하므로 isPressed는 넘기지 않음
        Bevel3DButtonLabel(color: type.blockColor, width: btnSize, height: btnSize, cornerRadius: radius,
                           topDepth: topDepth, botDepth: botDepth,
                           topOverlayOpacity: 0.28, bottomOverlayOpacity: 0.25) {
            Image(systemName: type.iconName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
        // 드래그 중: 0.88배 축소 + 반투명 / 눌린 상태: 0.93배 축소
        .scaleEffect(isDragging ? 0.88 : (isPressed ? 0.93 : 1.0))
        .opacity(isDragging ? 0.5 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.2,  dampingFraction: 0.8), value: isPressed)
        #if os(macOS)
        .gesture(dragGesture)
        #else
        .gesture(PaletteCardGesture(
            onPressChanged: { pressed in isPressed = pressed },
            onTap: onTap,
            onDragBegan: { point in
                guard dragEnabled else { return }
                withAnimation { isDragging = true }
                onDragStart?(point)
            },
            onDragChanged: { point in onDragChange?(point) },
            onDragEnded: { point in
                onDragEnd?(point)
                withAnimation { isDragging = false }
            }
        ))
        #endif
    }

    #if os(macOS)
    /// 맥용 제스처 — 0.38초 롱프레스 후 드래그 모드 전환, 아니면 탭으로 처리
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if isDragging {
                    // 이미 드래그 중이면 위치만 갱신
                    onDragChange?(value.location)
                } else if longPressTimer == nil && dragEnabled {
                    // 처음 터치 시 눌린 상태 표시 + 롱프레스 타이머 시작
                    withAnimation { isPressed = true }
                    let timer = Timer(timeInterval: 0.38, repeats: false) { _ in  // 0.38초 이상 누르면 드래그 시작
                        DispatchQueue.main.async {
                            // 드래그 모드 전환
                            withAnimation { isDragging = true; isPressed = false }
                            onDragStart?(value.location)
                        }
                    }
                    // 맥은 마우스 버튼을 누르고 있는 동안 .eventTracking 런루프로 전환되는데,
                    // .default 모드로 등록된 타이머는 그동안 멈춰서 롱프레스가 아예 감지되지 않음 —
                    // .common 모드로 등록해 드래그 중에도 타이머가 계속 돌도록 함
                    RunLoop.current.add(timer, forMode: .common)
                    longPressTimer = timer
                }
            }
            .onEnded { value in
                // 타이머 취소
                longPressTimer?.invalidate()
                longPressTimer = nil

                if isDragging {
                    // 드래그 종료 — 최종 위치 전달
                    onDragEnd?(value.location)
                } else {
                    // 탭 (드래그 없이 손가락 뗌) — 블럭 추가
                    onTap()
                }

                // 상태 초기화
                withAnimation { isDragging = false; isPressed = false }
            }
    }
    #endif
}

#if os(iOS)
// MARK: - PaletteCardRecognizer
/// 팔레트 카드 터치 인식기 — 눌림 표시, 탭, 0.38초 길게 눌러 끌기를 한곳에서 처리
/// SwiftUI 제스처로는 함께 만족시키지 못함 (LongPressGesture는 스크롤을 막고, Button과 인식기를 섞으면 연속 탭이 빠짐)
private final class PaletteCardRecognizer: UIGestureRecognizer {
    var onPressChanged: (Bool) -> Void = { _ in }
    var onTap: () -> Void = {}

    private var startPoint: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        // 두 번째 손가락은 무시
        guard numberOfTouches == 1, let touch = touches.first else {
            touches.forEach { ignore($0, for: event) }
            return
        }
        startPoint = touch.location(in: nil)
        onPressChanged(true)
        perform(#selector(beginDrag), with: nil, afterDelay: 0.38)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state == .possible else {
            state = .changed
            return
        }
        // 길게 누르기 전에 움직이면 실패 처리 — ScrollView가 스크롤을 이어받음
        guard let point = touches.first?.location(in: nil) else { return }
        if hypot(point.x - startPoint.x, point.y - startPoint.y) > 10 { state = .failed }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .possible {
            onTap()
            state = .failed
        } else {
            state = .ended
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = state == .possible ? .failed : .cancelled
    }

    /// 인식이 끝날 때마다 UIKit이 호출 — 대기 중인 드래그 시작을 취소하고 눌림 표시를 해제
    override func reset() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginDrag), object: nil)
        onPressChanged(false)
    }

    @objc private func beginDrag() {
        if state == .possible { state = .began }
    }
}

// MARK: - PaletteCardGesture
/// PaletteCardRecognizer를 SwiftUI에 연결 — 좌표는 글로벌 기준으로 전달
private struct PaletteCardGesture: UIGestureRecognizerRepresentable {
    let onPressChanged: (Bool) -> Void
    let onTap: () -> Void
    let onDragBegan: (CGPoint) -> Void
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> PaletteCardRecognizer {
        PaletteCardRecognizer()
    }

    func updateUIGestureRecognizer(_ recognizer: PaletteCardRecognizer, context: Context) {
        recognizer.onPressChanged = onPressChanged
        recognizer.onTap = onTap
    }

    func handleUIGestureRecognizerAction(_ recognizer: PaletteCardRecognizer, context: Context) {
        let point = context.converter.location(in: .global)
        switch recognizer.state {
        case .began: onDragBegan(point)
        case .changed: onDragChanged(point)
        case .ended: onDragEnded(point)
        case .cancelled: onDragEnded(.zero)  // (0,0)은 코드 영역 밖이라 삽입 없이 드래그만 취소됨
        default: break
        }
    }
}
#endif

// MARK: - Preview
#Preview {
    PaletteView(
        availableBlocks: BlockType.allCases,
        onSelect: { type in print("선택: \(type.displayName)") }
    )
    .padding(.vertical)
    .background(Color(red: 0.957, green: 0.925, blue: 0.843))
}
