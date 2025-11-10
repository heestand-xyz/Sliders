//
//  IncrementalSlider.swift
//
//
//  Created by Anton Heestand on 2021-04-24.
//

import SwiftUI

public struct IncrementalSlider: View {
    
    private static let coordinateSpaceName: String = "incremental-slider"
    private static let hitAreaPadding = EdgeInsets(
        top: 8,
        leading: 16,
        bottom: 8,
        trailing: 16
    )
    
    @Environment(\.colorScheme) private var colorScheme
        
    @Binding var relativeValue: CGFloat
    let defaultValue: CGFloat
        
    var willChange: () -> ()
    var didChange: (CGFloat, CGFloat) -> ()

    let relativeZero: CGFloat
    
    let relativeIncrement: CGFloat?
    
    let hint: Bool
    
    /// Incremental Slider
    public init(
        value: Binding<CGFloat>,
        default: CGFloat,
        minimum: CGFloat = 0.0,
        maximum: CGFloat = 1.0,
        increment: CGFloat? = nil,
        hint: Bool = false,
        willChange: @escaping () -> Void = {},
        didChange: @escaping (CGFloat, CGFloat) -> Void = { _, _ in }
    ) {
        let span: CGFloat = maximum - minimum
        _relativeValue = Binding {
            guard span != 0.0 else { return 0.0 }
            return (value.wrappedValue - minimum) / span
        } set: { newValue in
            value.wrappedValue = newValue * span + minimum
        }
        self.defaultValue = {
            guard span != 0.0 else { return 0.0 }
            return (`default` - minimum) / span
        }()
        self.willChange = willChange
        self.didChange = { oldValue, newValue in
            didChange(oldValue * span + minimum, newValue * span + minimum)
        }
        self.relativeZero = -minimum / span
        self.relativeIncrement = if let increment, span != 0.0 {
            increment / span
        } else { nil }
        self.hint = hint
    }
    
    /// Incremental Slider
    ///
    /// The relative value is between `0.0` and `1.0`
    init(
        relativeValue: Binding<CGFloat>,
        relativeDefault: CGFloat,
        relativeZero: CGFloat = 0.0,
        relativeIncrement: CGFloat? = nil,
        hint: Bool = false,
        willChange: @escaping () -> Void = {},
        didChange: @escaping (CGFloat, CGFloat) -> Void = { _, _ in }
    ) {
        _relativeValue = relativeValue
        self.defaultValue = relativeDefault
        self.willChange = willChange
        self.didChange = didChange
        self.relativeZero = relativeZero
        self.relativeIncrement = relativeIncrement
        self.hint = hint
    }
    
    private var incrementCount: Int {
        guard let increment: CGFloat = relativeIncrement else { return 1 }
        guard increment != 0.0 else { return 1 }
        let count: CGFloat = 1.0 / increment
        return Int(round(count * 1_000) / 1_000)
    }
    private let incrementValueRadius: CGFloat = 0.025
    
    private var barHeight: CGFloat {
#if os(macOS)
        5
#else
        6
#endif
    }
    private var headHeight: CGFloat {
#if os(macOS)
        18
#else
        25
#endif
    }
    private var headAspectRatio: CGFloat {
#if os(macOS)
        1.25
#else
        1.5
#endif
    }
    private var headLiftPadding: CGFloat {
#if os(macOS)
        1
#else
        3
#endif
    }
    private var headSize: CGSize {
        CGSize(width: headHeight * headAspectRatio, height: headHeight)
    }
    private var incrementSpacing: CGFloat {
        barHeight * 0.75
    }
    
    @State private var isDragging: Bool = false
    @State private var isEarlyDragging: Bool = false
    @State private var atIncrementIndex: Int?
    @State private var relativeStartValue: CGFloat?
    
    private var expand: Bool {
        isEarlyDragging || isDragging || hint
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.clear
                barContainer(size: geometry.size)
                    .padding(.horizontal, headSize.width / 2)
                headContainer(size: geometry.size)
                    .offset(x: fixedValue(from: relativeValue, at: geometry.size))
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .padding(Self.hitAreaPadding)
                    .contentShape(.capsule)
                    .gesture(dragGesture(size: geometry.size))
                    .simultaneousGesture(earlyDragGesture())
                    .padding(-Self.hitAreaPadding)
                    .offset(x: fixedValue(from: relativeStartValue ?? relativeValue, at: geometry.size))
            }
        }
        .frame(height: headSize.height)
        .coordinateSpace(name: Self.coordinateSpaceName)
        .padding(1)
        .compositingGroup()
        .onTapGesture(count: 2) {
            update(value: defaultValue)
        }
        .accessibilityLabel("Incremental Slider")
        .accessibilityValue("\(Int(relativeValue * 100))%")
        .accessibilityAction(named: "Reset to Default") {
            update(value: defaultValue)
        }
        .accessibilityAction(named: "Set to Minimum") {
            update(value: 0.0)
        }
        .accessibilityAction(named: "Set to Maximum") {
            update(value: 1.0)
        }
        .accessibilityAction(named: "Set to Zero") {
            update(value: relativeZero)
        }
    }
    
    private func fixedValue(from relativeValue: CGFloat, at size: CGSize) -> CGFloat {
        min(max(relativeValue, 0.0), 1.0) * (size.width - headSize.width)
    }
    
    private func barContainer(size: CGSize) -> some View {
        ZStack(alignment: .leading) {
            
            HStack(spacing: 0.0) {
                ForEach(0..<incrementCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: barHeight / 2)
                        .opacity(0.25)
                        .padding(.horizontal, incrementSpacing / 2)
                }
            }
            
            Rectangle()
                .frame(width: max(0, abs(min(max(relativeZero, 0.0), 1.0) - min(max(relativeValue, 0.0), 1.0)) * (size.width - headSize.width)))
                .offset(x: min(max(min(relativeZero, relativeValue), 0.0), 1.0) * (size.width - headSize.width))
                .foregroundColor(.accentColor)
                .frame(width: max(0, size.width - headSize.width), alignment: .leading)
                .mask(
                    HStack(spacing: 0.0) {
                        ForEach(0..<incrementCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: barHeight / 2)
                                .padding(.horizontal, incrementSpacing / 2)
                        }
                    }
                )
            
        }
        .frame(height: barHeight)
    }
    
    private func headContainer(size: CGSize) -> some View {
        Group {
            headContent
#if !os(macOS)
                .hoverEffect(.lift)
#endif
        }
        .padding(.horizontal, expand ? -headLiftPadding * headAspectRatio : 0)
        .padding(.vertical, expand ? -headLiftPadding : 0)
        .frame(width: headSize.width, height: headSize.height)
        .animation(.easeInOut(duration: 0.1), value: expand)
    }
    
    private var headContent: some View {
        Capsule()
            .foregroundColor(expand ? .primary.opacity(0.1) : .white)
            .overlay {
                Capsule()
                    .stroke(lineWidth: 1.5)
                    .opacity(0.2)
            }
            .overlay {
                Group {
                    if relativeValue == defaultValue {
                        Circle()
                            .frame(width: headSize.height / 3,
                                   height: headSize.height / 3)
                    } else {
                        Group {
                            if relativeValue < 0.0 {
                                Image(systemName: "chevron.left")
                            } else if relativeValue > 1.0 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .imageScale(.small)
                        .fontWeight(.black)
                    }
                }
                .foregroundColor(Color(white: 0.75))
            }
    }
    
    private func earlyDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isEarlyDragging {
                    isEarlyDragging = true
                }
            }
            .onEnded { _ in
                isEarlyDragging = false
            }
    }
    
    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(coordinateSpace: .named(Self.coordinateSpaceName))
            .onChanged { value in
                if !isDragging {
                    relativeStartValue = relativeValue
                    isDragging = true
                    willChange()
                }
                var value: CGFloat = (value.location.x - headSize.width / 2) / (size.width - headSize.width)
                value = min(max(value, 0.0), 1.0)
                if let incrementIndex: Int = findIncrementIndex(value) {
                    if atIncrementIndex != incrementIndex {
                        atIncrementIndex = incrementIndex
                        setIncrement(index: incrementIndex)
                    }
                } else {
                    if atIncrementIndex != nil {
                        atIncrementIndex = nil
                    }
                    set(value: value)
                }
            }
            .onEnded { _ in
                if let relativeStartValue: CGFloat {
                    didChange(relativeStartValue, relativeValue)
                }
                isDragging = false
                relativeStartValue = nil
            }
    }
    
    private func update(value: CGFloat) {
        let oldValue = relativeValue
        willChange()
        set(value: value)
        didChange(oldValue, value)
        haptic()
    }
    
    private func set(value: CGFloat) {
        relativeValue = value
    }
    
    private func setIncrement(index: Int) {
        relativeValue = incrementValue(index: index)
        haptic()
    }
                  
    private func haptic() {
        Task { @MainActor in
#if os(macOS)
            NSHapticFeedbackManager.defaultPerformer
                .perform(.generic, performanceTime: .now)
#elseif os(iOS)
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
#endif
        }
    }
    
    private func findIncrementIndex(_ value: CGFloat) -> Int? {
        for index in 0...incrementCount {
            let incrementValue: CGFloat = CGFloat(index) / CGFloat(incrementCount)
            if value > incrementValue - incrementValueRadius && value < incrementValue + incrementValueRadius {
                return index
            }
        }
        return nil
    }
    
    private func incrementValue(index: Int) -> CGFloat {
        CGFloat(index) * (1.0 / CGFloat(incrementCount))
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 1000)) {
    @Previewable @State var value: CGFloat = 0.5
    IncrementalSlider(
        value: $value,
        default: 0.5,
        minimum: 0.0,
        maximum: 1.0,
        increment: 0.25,
        willChange: {},
        didChange: { _, _ in }
    )
    .padding(10)
}

#Preview(traits: .fixedLayout(width: 200, height: 1000)) {
    @Previewable @State var value: CGFloat = -0.5
    IncrementalSlider(
        value: $value,
        default: 0.5,
        minimum: 0.0,
        maximum: 1.0,
        increment: 0.25,
        willChange: {},
        didChange: { _, _ in }
    )
    .padding(10)
}

#Preview(traits: .fixedLayout(width: 200, height: 1000)) {
    @Previewable @State var value: CGFloat = 1.5
    IncrementalSlider(
        value: $value,
        default: 0.5,
        minimum: -1.0,
        maximum: 1.0,
        increment: 0.25,
        willChange: {},
        didChange: { _, _ in }
    )
    .padding(10)
}
