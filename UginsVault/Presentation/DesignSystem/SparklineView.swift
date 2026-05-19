//
//  SparklineView.swift
//  UginsVault — Presentation: Design System
//
//  Small smoothed sparkline drawn with `Canvas` + `Path`. The math
//  lives in `SparklinePath` (pure, testable). The view layer composes
//  the stroked curve, a soft area fill underneath, and a 1pt dot at
//  the latest data point.
//

import SwiftUI

// MARK: - Pure math

public enum SparklinePath {

    /// Maps an oldest-first array of `Decimal` values into normalized
    /// `CGPoint`s laid out across the supplied `CGSize`. Robust to
    /// the degenerate cases: a single point lays at the vertical
    /// centre; an all-equal series renders as a flat mid-line so the
    /// caller doesn't divide-by-zero on the y-axis.
    public static func points(for values: [Decimal], in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty, size.width > 0, size.height > 0 else { return [] }
        let count = values.count

        if count == 1 {
            return [CGPoint(x: size.width / 2, y: size.height / 2)]
        }

        // Map to doubles once — Decimal -> Double is fine for layout math.
        let doubles = values.map { NSDecimalNumber(decimal: $0).doubleValue }
        let lo = doubles.min() ?? 0
        let hi = doubles.max() ?? 0
        let range = hi - lo

        let step = size.width / CGFloat(count - 1)
        return doubles.enumerated().map { index, value in
            let x = CGFloat(index) * step
            let normalized: Double
            if range == 0 {
                normalized = 0.5
            } else {
                normalized = (value - lo) / range
            }
            // Pad 4% top + bottom so the dot never clips against the
            // top edge.
            let y = size.height * CGFloat(1.0 - (normalized * 0.92 + 0.04))
            return CGPoint(x: x, y: y)
        }
    }

    /// Stroked smoothed path through `points`, using midpoint
    /// quad-curves. Skips bezier smoothing for the degenerate sub-2
    /// cases.
    public static func smoothPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 1 { return path }
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }
        for index in 1..<points.count {
            let prev = points[index - 1]
            let current = points[index]
            let mid = CGPoint(
                x: (prev.x + current.x) / 2,
                y: (prev.y + current.y) / 2
            )
            path.addQuadCurve(to: mid, control: prev)
            if index == points.count - 1 {
                path.addQuadCurve(to: current, control: current)
            }
        }
        return path
    }

    /// Closed area path under the smoothed line. Used to fill the
    /// soft tint below the curve.
    public static func areaPath(through points: [CGPoint], in size: CGSize) -> Path {
        guard let first = points.first, let last = points.last else { return Path() }
        var path = smoothPath(through: points)
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.addLine(to: CGPoint(x: first.x, y: size.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - View

public struct SparklineView: View {

    public let points: [Decimal]
    public let strokeColor: Color
    public let fillColor: Color

    @State private var trim: CGFloat = 0

    public init(
        points: [Decimal],
        strokeColor: Color = Color.uv.gold,
        fillColor: Color = Color.uv.gold
    ) {
        self.points = points
        self.strokeColor = strokeColor
        self.fillColor = fillColor
    }

    public var body: some View {
        GeometryReader { proxy in
            let mapped = SparklinePath.points(for: points, in: proxy.size)
            ZStack {
                SparklinePath.areaPath(through: mapped, in: proxy.size)
                    .fill(
                        LinearGradient(
                            colors: [fillColor.opacity(0.18), fillColor.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                SparklinePath.smoothPath(through: mapped)
                    .trim(from: 0, to: trim)
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                if let last = mapped.last, trim >= 1 {
                    Circle()
                        .fill(strokeColor)
                        .frame(width: Layout.sparklineDotSize, height: Layout.sparklineDotSize)
                        .position(x: last.x, y: last.y)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { trim = 1 }
            }
        }
        .accessibilityLabel("30-day value trend")
    }
}
