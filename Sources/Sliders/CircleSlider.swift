//
//  CircleSlider.swift
//  Properties
//
//  Created by Anton Heestand on 2021-09-09.
//

import SwiftUI

public struct CircleSliderMetadata: Equatable, Sendable {
    struct Data: Equatable, Sendable {
        let id: String
        var startAngle: Angle
        var currentAngle: Angle
    }
    public internal(set) var pressID: String?
    var isPressing: Bool {
        pressID != nil
    }
    var id: String? {
        data?.id ?? pressID
    }
    var data: Data?
    var anchorPoints: [String: CGPoint] = [:]
    var anchorPoint: CGPoint? {
        guard let id else { return nil }
        return anchorPoints[id]
    }
    public static let inactive: CircleSliderMetadata = .init()
    public static func press(id: String) -> CircleSliderMetadata {
        var metadata = CircleSliderMetadata()
        metadata.pressID = id
        return metadata
    }
    public init() {}
}

public struct CircleSliderButton: View {
    
    let id: String
    
    @Binding var value: CGFloat
    let valueScale: CGFloat

    @Binding var metadata: CircleSliderMetadata

    let coordinateSpace: CoordinateSpace

    var didStart: () -> ()
    var didEnd: (CGFloat, CGFloat) -> ()
    
    public init(
        id: String,
        value: Binding<CGFloat>,
        valueScale: CGFloat = 1.0,
        metadata: Binding<CircleSliderMetadata>,
        coordinateSpace: CoordinateSpace,
        willChange: @escaping () -> Void = {},
        didChange: @escaping (CGFloat, CGFloat) -> Void = { _, _ in}
    ) {
        self.id = id
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
    
//    @State private var changeCount: Int = 0
//    @State private var timeoutTimer: Timer?
    
    @State private var gestureState = GestureState<Bool?>()
    
    public var body: some View {
        Group {
            if isPressing {
                Circle()
                    .foregroundColor(.white)
            } else {
                ZStack {
                    Circle()
                        .foregroundColor(.accentColor)
                    Circle()
                        .foregroundStyle(.white)
                        .padding(CircleSliderOverlay.thickness / 4)
                }
            }
        }
        .frame(width: CircleSliderOverlay.thickness,
               height: CircleSliderOverlay.thickness)
        .opacity(metadata.data?.id == id ? 0.0 : 1.0)
        .onGeometryChange(for: CGPoint.self) { geometry in
            let frame = geometry.frame(in: coordinateSpace)
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { newPoint in
            metadata.anchorPoints[id] = newPoint
        }
        .frame(width: CircleSliderOverlay.thickness * 2,
               height: CircleSliderOverlay.thickness * 2)
        .contentShape(.circle)
        .gesture(dragGesture)
        .simultaneousGesture(pressGesture)
        .accessibilityLabel("Circle Slider")
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let angle = Angle(radians: atan2(value.translation.height, value.translation.width))
                if metadata.data == nil {
                    metadata.data = CircleSliderMetadata.Data(id: id, startAngle: angle, currentAngle: .zero)
                    startValue = self.value
                    didStart()
//                    timeoutTimer = Timer(timeInterval: 0.1, repeats: false, block: { _ in
//                        Task { @MainActor in
//                            guard changeCount == 1 else { return }
//                            metadata.data = nil
//                            lastAngle = nil
//                            changeCount = 0
//                            timeoutTimer = nil
//                        }
//                    })
//                    RunLoop.current.add(timeoutTimer!, forMode: .common)
                } else if let data = metadata.data, lastAngle != nil, let startValue {
                    guard data.id == id else { return }
                    let relativeAngle: Angle = narrow(angle: angle - lastAngle!)
                    let currentAngle: Angle = metadata.data!.currentAngle + relativeAngle
                    metadata.data!.currentAngle = currentAngle
                    self.value = startValue + (currentAngle.degrees / 360) * valueScale
                }
                guard metadata.data?.id == id else { return }
                lastAngle = angle
//                changeCount += 1
            }
            .onEnded { _ in
                guard let data = metadata.data, data.id == id else { return }
                if let startValue: CGFloat = startValue {
                    let value: CGFloat = (data.currentAngle.degrees / 360) * valueScale
                    didEnd(startValue, value)
                }
                metadata.data = nil
                startValue = nil
                lastAngle = nil
//                changeCount = 0
//                timeoutTimer?.invalidate()
//                timeoutTimer = nil
            }
    }
    
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0.0)
            .onChanged { value in
                if !isPressing {
                    isPressing = true
                    metadata.pressID = id
                }
            }
            .onEnded { _ in
                isPressing = false
                if metadata.pressID == id {
                    metadata.pressID = nil
                }
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
            if let anchorPoint: CGPoint = metadata.anchorPoint {
                ZStack {
                    if let data: CircleSliderMetadata.Data = metadata.data {
                        mainBody(data: data)
                    } else if metadata.isPressing {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle()
                                    .opacity(0.1)
                            }
                            .mask(circleWithHole())
                    }
                }
                .offset(x: anchorPoint.x - geometry.frame(in: coordinateSpace).midX,
                        y: anchorPoint.y - geometry.frame(in: coordinateSpace).midY)
            }
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
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .opacity(0.1)
                }
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
            id: "first",
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
