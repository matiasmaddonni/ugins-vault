//
//  DonutChartView.swift
//  UginsVault — Presentation: Design System
//
//  Donut chart drawn with `Canvas` / `Path.arc` over a faint track
//  ring. The angle math lives in `DonutArcs` (pure, testable). The
//  view layer animates each slice's `endAngle` on appear, with a
//  small per-slice delay so the donut "fills in" rather than blooming
//  all at once.
//

import SwiftUI

// MARK: - Pure math

public enum DonutArcs {

    public struct Arc: Equatable, Sendable {
        public let id: String
        public let start: Angle
        public let end: Angle
        public let colorHex: UInt32

        public init(id: String, start: Angle, end: Angle, colorHex: UInt32) {
            self.id = id
            self.start = start
            self.end = end
            self.colorHex = colorHex
        }
    }

    /// Builds an arc list from the supplied slices. Zero-value slices
    /// are skipped (they'd render as ambiguous hairlines). The arcs
    /// sweep clockwise from 12 o'clock and the angles sum to 2π
    /// across the kept slices.
    public static func arcs(for slices: [FormatSlice]) -> [Arc] {
        let total = slices.reduce(Decimal(0)) { $0 + $1.valueUSD }
        guard total > 0 else { return [] }

        var arcs: [Arc] = []
        var cursor = Angle.degrees(-90)              // start at 12 o'clock
        for slice in slices where slice.valueUSD > 0 {
            let fraction = NSDecimalNumber(decimal: slice.valueUSD).doubleValue
                         / NSDecimalNumber(decimal: total).doubleValue
            let sweep = Angle.degrees(fraction * 360)
            let end = Angle.degrees(cursor.degrees + sweep.degrees)
            arcs.append(Arc(id: slice.id, start: cursor, end: end, colorHex: slice.colorHex))
            cursor = end
        }
        return arcs
    }
}

// MARK: - View

public struct DonutChartView<Center: View>: View {

    public let slices: [FormatSlice]
    public let size: CGFloat
    public let thickness: CGFloat
    private let center: () -> Center

    @State private var progress: Double = 0

    public init(
        slices: [FormatSlice],
        size: CGFloat,
        thickness: CGFloat,
        @ViewBuilder center: @escaping () -> Center
    ) {
        self.slices = slices
        self.size = size
        self.thickness = thickness
        self.center = center
    }

    public var body: some View {
        let arcs = DonutArcs.arcs(for: slices)

        ZStack {
            Circle()
                .stroke(Color.uv.strokeHi.opacity(0.4), lineWidth: thickness)

            ForEach(Array(arcs.enumerated()), id: \.element.id) { _, arc in
                AnimatableArcShape(start: arc.start, end: arc.end, progress: progress)
                    .stroke(Color(hex: arc.colorHex), style: StrokeStyle(lineWidth: thickness, lineCap: .butt))
            }

            center()
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { progress = 1 }
        }
    }
}

private struct AnimatableArcShape: Shape {

    let start: Angle
    let end: Angle
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = (min(rect.width, rect.height) / 2)
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let sweep = end.degrees - start.degrees
        let animatedEnd = Angle.degrees(start.degrees + sweep * progress)

        var path = Path()
        path.addArc(
            center: centerPoint,
            radius: radius,
            startAngle: start,
            endAngle: animatedEnd,
            clockwise: false
        )
        return path
    }
}
