//
//  CircleSlider.swift
//  Properties
//
//  Created by Anton Heestand on 2021-09-09.
//

import SwiftUI

public struct CircleSliderMetadata: Sendable {
    struct Data: Sendable {
        var startAngle: Angle
        var currentAngle: Angle
    }
    var isPressing: Bool = false
    var data: Data?
    var anchorPoint: CGPoint = .zero
    public static let inactive: CircleSliderMetadata = .init()
    public init() {}
}

public struct CircleSliderButton: View {
    
    @Binding var value: CGFloat
    let valueScale: CGFloat

    @Binding var metadata: CircleSliderMetadata

    let coordinateSpace: CoordinateSpace

    var didStart: () -> ()
    var didEnd: (CGFloat, CGFloat) -> ()
    
    init(
        value: Binding<CGFloat>,
        valueScale: CGFloat = 1.0,
        metadata: Binding<CircleSliderMetadata>,
        coordinateSpace: CoordinateSpace,
        willChange: @escaping () -> Void = {},
        didChange: @escaping (CGFloat, CGFloat) -> Void = { _, _ in}
    ) {
        _value = value
        self.valueScale = valueScale
        _metadata = metadata
        self.coordinateSpace = coordinateSpace
        self.didStart = willChange
        self.didEnd = didChange
    }
    
    @State private var isPressing: Bool = false
    
    @State private var startValue: CGFloat?
    @State private var lastAngle: Angle?
    
    @State private var changeCount: Int = 0
    @State private var timeoutTimer: Timer?
    
    @State private var gestureState = GestureState<Bool?>()
    
    public var body: some View {
        Group {
            if isPressing {
                Circle()
                    .foregroundColor(.white)
            } else {
                Circle()
                    .subtracting(Circle().inset(by: CircleSliderOverlay.thickness / 4))
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: CircleSliderOverlay.thickness,
               height: CircleSliderOverlay.thickness)
        .opacity(metadata.data != nil ? 0.0 : 1.0)
        .zIndex(10)
        .onGeometryChange(for: CGPoint.self) { geometry in
            let frame = geometry.frame(in: coordinateSpace)
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { newPoint in
            metadata.anchorPoint = newPoint
        }
        .frame(width: CircleSliderOverlay.thickness * 2,
               height: CircleSliderOverlay.thickness * 2)
        .contentShape(.circle)
        .gesture(dragGesture)
        .simultaneousGesture(pressGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let angle = Angle(radians: atan2(value.translation.height, value.translation.width))
                if metadata.data == nil {
                    metadata.data = CircleSliderMetadata.Data(startAngle: angle, currentAngle: .zero)
                    startValue = self.value
                    didStart()
                    timeoutTimer = Timer(timeInterval: 0.1, repeats: false, block: { _ in
                        Task { @MainActor in
                            guard changeCount == 1 else { return }
                            metadata.data = nil
                            lastAngle = nil
                            changeCount = 0
                            timeoutTimer = nil
                        }
                    })
                    RunLoop.current.add(timeoutTimer!, forMode: .common)
                } else if metadata.data != nil, lastAngle != nil {
                    let relativeAngle = narrow(angle: angle - lastAngle!)
                    metadata.data!.currentAngle += relativeAngle
                    self.value += (relativeAngle.degrees / 360) * valueScale
                }
                lastAngle = angle
                changeCount += 1
            }
            .onEnded { _ in
                if metadata.data != nil, let startValue: CGFloat = startValue {
                    let value: CGFloat = (metadata.data!.currentAngle.degrees / 360) * valueScale
                    didEnd(startValue, value)
                }
                metadata.data = nil
                lastAngle = nil
                changeCount = 0
                timeoutTimer?.invalidate()
                timeoutTimer = nil
            }
    }
    
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0.0)
            .onChanged { value in
                if !isPressing {
                    isPressing = true
                    metadata.isPressing = true
                }
            }
            .onEnded { _ in
                isPressing = false
                metadata.isPressing = false
            }
    }
    
    private func narrow(angle: Angle) -> Angle {
        var angle: Angle = angle
        if angle.degrees > 0.0 {
            if angle.degrees > 180 {
                angle -= Angle(degrees: 360)
            }
        } else if angle.degrees < 0.0 {
            if angle.degrees < -180 {
                angle += Angle(degrees: 360)
            }
        }
        return angle
    }
}

public struct CircleSliderOverlay: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let metadata: CircleSliderMetadata
    let coordinateSpace: CoordinateSpace
    
    public init(
        metadata: CircleSliderMetadata,
        coordinateSpace: CoordinateSpace
    ) {
        self.metadata = metadata
        self.coordinateSpace = coordinateSpace
    }

    static var radius: CGFloat {
#if os(macOS)
        40
#else
        60
#endif
    }
    static var thickness: CGFloat {
#if os(macOS)
        20
#else
        40
#endif
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let data: CircleSliderMetadata.Data = metadata.data {
                    mainBody(data: data)
                } else if metadata.isPressing {
                    Color(white: colorScheme == .light ? 0.8 : 0.3)
                        .mask(circleWithHole())
                }
            }
            .offset(x: metadata.anchorPoint.x - geometry.frame(in: coordinateSpace).midX,
                    y: metadata.anchorPoint.y - geometry.frame(in: coordinateSpace).midY)
        }
        .frame(width: Self.radius * 2,
               height: Self.radius * 2)
    }
    
    @ViewBuilder
    func mainBody(data: CircleSliderMetadata.Data) -> some View {
        
        var startAngle: Angle {
            data.startAngle
        }
        var currentAngle: Angle {
            data.currentAngle
        }
        var angle: Angle {
            startAngle + currentAngle
        }
        
        ZStack {
            /// Donut
            Color(white: colorScheme == .light ? 0.8 : 0.3)
                .mask(circleWithHole())
            /// Fill
            Group {
                /// Arc
                CircleSliderArcShape(
                    width: Self.thickness,
                    angle: narrow(angle: Angle(degrees: startAngle.degrees + angle.degrees) / 2.0),
                    length: Angle(degrees: abs(startAngle.degrees - angle.degrees))
                )
                /// Start Circle
                Circle()
                    .frame(width: Self.thickness, height: Self.thickness)
                    .offset(x: cos(startAngle.radians) * (Self.radius - Self.thickness / 2),
                            y: sin(startAngle.radians) * (Self.radius - Self.thickness / 2))
            }
            .foregroundColor(.accentColor)
            /// Current Circle
            Circle()
                .foregroundColor(.white)
                .overlay {
                    Circle()
                        .stroke()
                        .opacity(0.2)
                }
                .frame(width: Self.thickness, height: Self.thickness)
                .offset(x: cos(angle.radians) * (Self.radius - Self.thickness / 2),
                        y: sin(angle.radians) * (Self.radius - Self.thickness / 2))
        }
        .compositingGroup()
    }
    
    private func circleWithHole() -> some View {
        ZStack {
            Circle()
                .foregroundColor(.white)
            Circle()
                .foregroundColor(.black)
                .mask(
                    Circle()
                        .padding(Self.thickness)
                )
        }
            .compositingGroup()
            .luminanceToAlpha()
    }
    
    private func narrow(angle: Angle) -> Angle {
        var angle: Angle = angle
        if angle.degrees > 0.0 {
            if angle.degrees > 180 {
                angle -= Angle(degrees: 360)
            }
        } else if angle.degrees < 0.0 {
            if angle.degrees < -180 {
                angle += Angle(degrees: 360)
            }
        }
        return angle
    }
}

struct CircleSliderArcShape: Shape {
    
    let width: CGFloat
    let angle: Angle
    let length: Angle
    
    func path(in rect: CGRect) -> Path {
        
        let outerRadius: CGFloat = min(rect.width, rect.height) / 2
        let innerRadius: CGFloat = outerRadius - width
        
        return Path { path in
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: innerRadius,
                        startAngle: angle - length / 2,
                        endAngle: angle + length / 2,
                        clockwise: false)
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: outerRadius,
                        startAngle: angle + length / 2,
                        endAngle: angle - length / 2,
                        clockwise: true)
        }
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 200)) {
    @Previewable @State var value: CGFloat = 0.0
    @Previewable @State var metadata: CircleSliderMetadata = .inactive
    let coordinateSpaceName: String = "circle-slider"
    ZStack {
        CircleSliderButton(
            value: $value,
            valueScale: 1.0,
            metadata: $metadata,
            coordinateSpace: .named(coordinateSpaceName),
            willChange: {},
            didChange: { _, _ in }
        )
        CircleSliderOverlay(
            metadata: metadata,
            coordinateSpace: .named(coordinateSpaceName)
        )
    }
    .frame(width: 200, height: 200)
    .coordinateSpace(name: coordinateSpaceName)
}
