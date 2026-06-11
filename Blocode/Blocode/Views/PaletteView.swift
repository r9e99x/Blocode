//
//  PaletteView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

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

    /// 팔레트 카드 컨테이너 배경 — 다크/라이트 모드 대응
    private var containerColor: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.19, blue: 0.23, alpha: 1.0)
                : UIColor(red: 251/255, green: 246/255, blue: 232/255, alpha: 1.0) // #fbf6e8
        })
    }

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
            .padding(.vertical, 12)
        }
        .background(containerColor)
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
    @State private var longPressTimer: Timer? = nil  // 롱프레스 감지 타이머

    /// 드래그 활성화 여부 — onDragStart 콜백이 있을 때만 활성화
    private var dragEnabled: Bool { onDragStart != nil }

    // 3D 카드 파라미터
    private let btnSize:   CGFloat = 54   // 버튼 크기
    private let radius:    CGFloat = 16   // 모서리 반지름
    private let topDepth:  CGFloat = 2    // 위 뒷면 두께
    private let botDepth:  CGFloat = 3.5  // 아래 뒷면 두께

    var body: some View {
        ZStack(alignment: .top) {

            // ① 위 뒷면 — blockColor + white 0.28 (앞면보다 위에 살짝 보임)
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(type.blockColor)
                RoundedRectangle(cornerRadius: radius).fill(Color.white.opacity(0.28))
            }
            .frame(width: btnSize, height: btnSize)

            // ② 아래 뒷면 — blockColor + black 0.25 (그림자 효과)
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(type.blockColor)
                RoundedRectangle(cornerRadius: radius).fill(Color.black.opacity(0.25))
            }
            .frame(width: btnSize, height: btnSize)
            .offset(y: topDepth + botDepth)  // 앞면 아래로 이동

            // ③ 앞면 — blockColor + 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(type.blockColor)
                Image(systemName: type.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: btnSize, height: btnSize)
            .offset(y: topDepth)  // 위 뒷면이 보이도록 아래로 오프셋
        }
        .frame(width: btnSize, height: btnSize + topDepth + botDepth)
        // 드래그 중: 0.88배 축소 + 반투명 / 눌린 상태: 0.93배 축소
        .scaleEffect(isDragging ? 0.88 : (isPressed ? 0.93 : 1.0))
        .opacity(isDragging ? 0.5 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.2,  dampingFraction: 0.8), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if isDragging {
                        // 이미 드래그 중이면 위치만 갱신
                        onDragChange?(value.location)
                    } else if longPressTimer == nil && dragEnabled {
                        // 처음 터치 시 눌린 상태 표시 + 롱프레스 타이머 시작
                        withAnimation { isPressed = true }
                        longPressTimer = Timer.scheduledTimer(
                            withTimeInterval: 0.38,  // 0.38초 이상 누르면 드래그 시작
                            repeats: false
                        ) { _ in
                            DispatchQueue.main.async {
                                // 드래그 모드 전환
                                withAnimation { isDragging = true; isPressed = false }
                                onDragStart?(value.location)
                            }
                        }
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
        )
    }
}

// MARK: - Preview
#Preview {
    PaletteView(
        availableBlocks: BlockType.allCases,
        onSelect: { type in print("선택: \(type.displayName)") }
    )
    .padding(.vertical)
    .background(Color(red: 0.957, green: 0.925, blue: 0.843))
}
