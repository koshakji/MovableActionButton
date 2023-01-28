import SwiftUI


private func distance(from: (x: CGFloat, y: CGFloat), to: (x: CGFloat, y: CGFloat)) -> CGFloat {
    return sqrt((from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y))
}


@available(macOS 10.15, *)
struct MovableActionButton<FAB: View>: ViewModifier {
    @State var alignment = Alignment.bottomTrailing
    var allowedAllignments: [Alignment] = [
        .bottomLeading, .bottom, .bottomTrailing,
        .leading, .trailing,
        .topLeading, .top, .topTrailing
    ]
    let actionButton: () -> FAB
    
    let onAlignmentChanged: ((Alignment) -> Void)?
    
    @State private var dragAmount = CGSize.zero
    @Environment(\.layoutDirection) var layoutDirection
    

    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: alignment) {
                content
                actionButton()
                    .offset(dragAmount)
                    .highPriorityGesture(
                        DragGesture()
                            .onChanged { value in
                                self.dragAmount = value.translation
                            }.onEnded { value in
                                dragEnded(value: value, geometry: geometry)
                            }
                    )
                
            }
        }
    }
    
    func dragEnded(value: DragGesture.Value, geometry: GeometryProxy) {
        let frame = geometry.frame(in: .local)
        let end = value.predictedEndLocation
        
        let leading = self.layoutDirection == .leftToRight ? frame.minX : frame.maxX
        let trailing = self.layoutDirection == .leftToRight ? frame.maxX : frame.minX
        let top = frame.minY
        let bottom = frame.maxY
        let centerX = frame.midX
        let centerY = frame.midY
        
        let positionX: CGFloat
        switch alignment {
        case .bottomLeading, .leading, .topLeading:
            positionX = leading + end.x
        case .bottom, .center, .top:
            positionX = centerX + end.x
        case .bottomTrailing, .trailing, .topTrailing:
            positionX = trailing + end.x
        default:
            positionX = .zero
        }
        
        let positionY: CGFloat
        switch alignment {
        case .top, .topLeading, .topTrailing:
            positionY = top + end.y
        case .center, .leading, .trailing:
            positionY = centerY + end.y
        case .bottom, .bottomLeading, .bottomTrailing:
            positionY = bottom + end.y
        default:
            positionY = .zero
        }
        
        let points: [(x: CGFloat, y: CGFloat, alignment: Alignment)] = [
            (x: leading,  y: bottom, alignment: .bottomLeading),
            (x: centerX,  y: bottom, alignment: .bottom),
            (x: trailing, y: bottom, alignment: .bottomTrailing),
            
            (x: leading,  y: centerY, alignment: .leading),
            (x: centerX,  y: centerY, alignment: .center),
            (x: trailing, y: centerY, alignment: .trailing),
            
            (x: leading,  y: top, alignment: .topLeading),
            (x: centerX,  y: top, alignment: .top),
            (x: trailing, y: top, alignment: .topTrailing),
        ]
        
        
        let distAlignment = points.filter {
            self.allowedAllignments.contains($0.alignment)
        }.map { alignmentPoint in
            return (
                distance: distance(
                    from: (positionX, positionY),
                    to: (alignmentPoint.x, alignmentPoint.y)
                ),
                alignment: alignmentPoint.alignment
            )
        }.sorted { $0.distance < $1.distance }
        
        
        guard let newAlignment = distAlignment.first?.alignment else {
            self.dragAmount = .zero
            return
        }
        
        if newAlignment != self.alignment {
            self.onAlignmentChanged?(newAlignment)
            withAnimation {
                self.alignment = newAlignment
                self.dragAmount = .zero
            }
        }
    }
    
}

public extension View {
    func withMovableActionButton<FAB: View>(
        alignment: Alignment = .bottomTrailing,
        allowedAlignments: [Alignment] = [.bottomLeading, .bottomTrailing, .topLeading, .topTrailing],
        actionButton: @escaping ()->FAB,
        onAlignmentChanged: ((Alignment) -> Void)? = nil
    ) -> some View {
        self.modifier(
            MovableActionButton(
                alignment: alignment,
                allowedAllignments: allowedAlignments,
                actionButton: actionButton,
                onAlignmentChanged: onAlignmentChanged
            )
        )
    }
}

