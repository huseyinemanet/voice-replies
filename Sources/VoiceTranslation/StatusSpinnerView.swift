import AppKit

final class StatusSpinnerView: NSView {
    private var timer: Timer?
    private var frameIndex = 0

    func startSpinning() {
        guard timer == nil else { return }
        isHidden = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 18.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            frameIndex = (frameIndex + 1) % 12
            needsDisplay = true
        }
    }

    func stopSpinning() {
        timer?.invalidate()
        timer = nil
        isHidden = true
        frameIndex = 0
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard !isHidden else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let tickCount = 12
        let outerRadius = min(bounds.width, bounds.height) * 0.42
        let innerRadius = outerRadius * 0.56

        effectiveAppearance.performAsCurrentDrawingAppearance {
            let color = NSColor.labelColor

            for tick in 0..<tickCount {
                let position = (tick + frameIndex) % tickCount
                let alpha = 0.18 + (CGFloat(position) / CGFloat(tickCount - 1)) * 0.82
                let angle = (CGFloat(tick) / CGFloat(tickCount)) * 2 * CGFloat.pi

                let start = CGPoint(
                    x: center.x + cos(angle) * innerRadius,
                    y: center.y + sin(angle) * innerRadius
                )
                let end = CGPoint(
                    x: center.x + cos(angle) * outerRadius,
                    y: center.y + sin(angle) * outerRadius
                )

                let path = NSBezierPath()
                path.move(to: start)
                path.line(to: end)
                path.lineWidth = 1.7
                path.lineCapStyle = .round
                color.withAlphaComponent(alpha).setStroke()
                path.stroke()
            }
        }
    }
}
