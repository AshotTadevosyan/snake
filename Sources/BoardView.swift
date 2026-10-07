import AppKit

enum Palette {
    static let background = NSColor(srgbRed: 0.055, green: 0.079, blue: 0.071, alpha: 1)
    static let board = NSColor(srgbRed: 0.079, green: 0.111, blue: 0.097, alpha: 1)
    static let mint = NSColor(srgbRed: 0.69, green: 0.94, blue: 0.48, alpha: 1)
    static let text = NSColor(srgbRed: 0.93, green: 0.96, blue: 0.89, alpha: 1)
    static let muted = NSColor(srgbRed: 0.53, green: 0.63, blue: 0.56, alpha: 1)
    static let coral = NSColor(srgbRed: 1, green: 0.47, blue: 0.36, alpha: 1)
}

final class BoardView: NSView {
    var game = SnakeGame() { didSet { needsDisplay = true } }
    var onDirection: ((Direction) -> Void)?
    var onPrimary: (() -> Void)?
    var onPause: (() -> Void)?
    var onRestart: (() -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Snake game board")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }

    override func keyDown(with event: NSEvent) {
        guard !event.modifierFlags.contains(.command) else { super.keyDown(with: event); return }
        switch event.keyCode {
        case 123: onDirection?(.left)
        case 124: onDirection?(.right)
        case 125: onDirection?(.down)
        case 126: onDirection?(.up)
        case 49: if !event.isARepeat { onPrimary?() }
        case 36: if !event.isARepeat { onPrimary?() }
        case 53: if !event.isARepeat { onPause?() }
        default:
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "w": onDirection?(.up)
            case "a": onDirection?(.left)
            case "s": onDirection?(.down)
            case "d": onDirection?(.right)
            case "p": if !event.isARepeat { onPause?() }
            case "r": if !event.isARepeat { onRestart?() }
            default: super.keyDown(with: event)
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        Palette.board.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16).fill()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16).addClip()
        let cell = min(bounds.width / CGFloat(game.columns), bounds.height / CGFloat(game.rows))
        let origin = NSPoint(x: (bounds.width - cell * CGFloat(game.columns)) / 2,
                             y: (bounds.height - cell * CGFloat(game.rows)) / 2)
        func cellRect(_ p: Cell) -> NSRect {
            NSRect(x: origin.x + CGFloat(p.x) * cell, y: origin.y + CGFloat(p.y) * cell,
                   width: cell, height: cell)
        }
        NSColor.white.withAlphaComponent(0.045).setFill()
        for y in 0..<game.rows {
            for x in 0..<game.columns {
                let r = cellRect(Cell(x: x, y: y))
                NSBezierPath(ovalIn: NSRect(x: r.midX - 1, y: r.midY - 1, width: 2, height: 2)).fill()
            }
        }
        if let food = game.food {
            let r = cellRect(food)
            Palette.coral.withAlphaComponent(0.12).setFill()
            NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1)).fill()
            Palette.coral.setFill()
            NSBezierPath(ovalIn: r.insetBy(dx: cell * 0.24, dy: cell * 0.24)).fill()
            NSColor.white.withAlphaComponent(0.5).setFill()
            NSBezierPath(ovalIn: NSRect(x: r.midX - 3, y: r.midY - 4, width: 3, height: 3)).fill()
        }
        for (index, segment) in game.snake.enumerated().reversed() {
            let r = cellRect(segment).insetBy(dx: 1.5, dy: 1.5)
            let alpha = index == 0 ? 1.0 : max(0.48, 0.88 - Double(index) * 0.008)
            Palette.mint.withAlphaComponent(alpha).setFill()
            NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6).fill()
            if index == 0 {
                let d = game.direction.offset
                let cx = r.midX + CGFloat(d.0) * 4, cy = r.midY + CGFloat(d.1) * 4
                Palette.background.setFill()
                for side in [-1.0, 1.0] {
                    let ex = cx + (d.0 == 0 ? side * 4 : 0)
                    let ey = cy + (d.1 == 0 ? side * 4 : 0)
                    NSBezierPath(ovalIn: NSRect(x: ex - 1.5, y: ey - 1.5, width: 3, height: 3)).fill()
                }
            }
        }
        if game.phase != .running {
            Palette.background.withAlphaComponent(0.79).setFill()
            rect.fill()
            let title: String
            let subtitle: String
            switch game.phase {
            case .ready: title = "A little focus. A longer snake."; subtitle = "Press Space to start"
            case .paused: title = "Take a breather."; subtitle = "Press Space to resume"
            case .gameOver: title = "One more round?"; subtitle = "Game over · \(game.score) points · Space to play again"
            case .won: title = "Every square. All yours."; subtitle = "Board cleared! · Space to play again"
            case .running: title = ""; subtitle = ""
            }
            drawText(title, y: bounds.midY - 23, font: .systemFont(ofSize: 26, weight: .semibold), color: Palette.text)
            drawText(subtitle, y: bounds.midY + 20, font: .systemFont(ofSize: 14), color: Palette.muted)
        }
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.withAlphaComponent(0.09).setStroke()
        let border = NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16)
        border.lineWidth = 1
        border.stroke()
    }

    private func drawText(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: y), withAttributes: attributes)
    }
}
