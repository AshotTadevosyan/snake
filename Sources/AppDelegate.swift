import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private let board = BoardView()
    private var game = SnakeGame()
    private let highScore = HighScoreStore()
    private var timer: Timer?
    private let scoreLabel = NSTextField(labelWithString: "000")
    private let bestLabel = NSTextField(labelWithString: "000")
    private let statusLabel = NSTextField(labelWithString: "READY WHEN YOU ARE")
    private let startButton = NSButton(title: "Start game", target: nil, action: nil)
    private let pauseButton = NSButton(title: "Pause", target: nil, action: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMenu()
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 730),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Snake"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = Palette.background
        window.appearance = NSAppearance(named: .darkAqua)
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        makeInterface()
        board.onDirection = { [weak self] in self?.game.turn($0) }
        board.onPrimary = { [weak self] in self?.primary() }
        board.onPause = { [weak self] in self?.pause() }
        board.onRestart = { [weak self] in self?.restart() }
        refresh()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(board)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Snake", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Snake", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Snake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let gameItem = NSMenuItem()
        let gameMenu = NSMenu(title: "Game")
        let restart = gameMenu.addItem(withTitle: "New Game", action: #selector(restart), keyEquivalent: "n")
        restart.target = self
        let pause = gameMenu.addItem(withTitle: "Pause / Resume", action: #selector(pause), keyEquivalent: "p")
        pause.target = self
        gameItem.submenu = gameMenu
        menu.addItem(gameItem)
        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = windowMenu
        menu.addItem(windowItem)
        NSApp.mainMenu = menu
        NSApp.windowsMenu = windowMenu
    }

    private func makeInterface() {
        guard let root = window.contentView else { return }
        func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
            let field = NSTextField(labelWithString: text)
            field.font = .systemFont(ofSize: size, weight: weight)
            field.textColor = color
            return field
        }
        func add(_ view: NSView, _ frame: NSRect) { view.frame = frame; root.addSubview(view) }
        add(label("SNAKE", size: 32, weight: .bold, color: Palette.text), NSRect(x: 36, y: 657, width: 220, height: 42))
        add(label("THE CLASSIC. A FRESH START.", size: 10, weight: .medium, color: Palette.muted), NSRect(x: 38, y: 637, width: 300, height: 18))
        for (x, title, field) in [(CGFloat(490), "SCORE", scoreLabel), (CGFloat(598), "BEST", bestLabel)] {
            add(label(title, size: 10, weight: .semibold, color: Palette.muted), NSRect(x: x, y: 682, width: 90, height: 15))
            field.font = .monospacedDigitSystemFont(ofSize: 28, weight: .medium)
            field.textColor = Palette.text
            add(field, NSRect(x: x, y: 646, width: 98, height: 36))
        }
        statusLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        statusLabel.textColor = Palette.mint
        add(statusLabel, NSRect(x: 38, y: 605, width: 640, height: 18))
        add(board, NSRect(x: 72, y: 112, width: 576, height: 480))
        startButton.target = self
        startButton.action = #selector(restart)
        startButton.bezelStyle = .rounded
        startButton.bezelColor = Palette.mint
        startButton.contentTintColor = Palette.background
        startButton.font = .systemFont(ofSize: 13, weight: .semibold)
        add(startButton, NSRect(x: 32, y: 60, width: 134, height: 34))
        pauseButton.target = self
        pauseButton.action = #selector(pause)
        pauseButton.bezelStyle = .rounded
        add(pauseButton, NSRect(x: 175, y: 60, width: 104, height: 34))
        add(label("Eat. Grow. Keep going.", size: 13, weight: .regular, color: Palette.muted), NSRect(x: 432, y: 68, width: 250, height: 20))
        add(label("↑ ↓ ← →  /  WASD   Move        SPACE   Start / pause        R   Restart", size: 11, weight: .regular, color: Palette.muted), NSRect(x: 38, y: 24, width: 646, height: 20))
    }

    @objc private func restart() {
        game.start()
        refresh()
        scheduleTick()
        window.makeFirstResponder(board)
    }

    private func primary() {
        if game.phase == .running || game.phase == .paused { pause() }
        else { restart() }
    }

    @objc private func pause() {
        game.togglePause()
        refresh()
        scheduleTick()
        window.makeFirstResponder(board)
    }

    private func scheduleTick() {
        timer?.invalidate()
        timer = nil
        guard game.phase == .running else { return }
        let next = Timer(timeInterval: game.tickInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.game.tick()
            self.highScore.record(self.game.score)
            self.refresh()
            self.scheduleTick()
        }
        timer = next
        RunLoop.main.add(next, forMode: .common)
    }

    private func refresh() {
        board.game = game
        scoreLabel.stringValue = String(format: "%03d", game.score)
        bestLabel.stringValue = String(format: "%03d", highScore.value)
        startButton.title = game.phase == .ready ? "Start game" : "Restart"
        pauseButton.title = game.phase == .paused ? "Resume" : "Pause"
        pauseButton.isEnabled = game.phase == .running || game.phase == .paused
        switch game.phase {
        case .ready: statusLabel.stringValue = "●  READY WHEN YOU ARE"
        case .running: statusLabel.stringValue = "●  LEVEL \(game.level)    /    \(game.snake.count) SEGMENTS"
        case .paused: statusLabel.stringValue = "Ⅱ  PAUSED"
        case .gameOver: statusLabel.stringValue = "●  GAME OVER    /    MAKE YOUR NEXT MOVE"
        case .won: statusLabel.stringValue = "●  BOARD CLEARED"
        }
        board.setAccessibilityValue("\(statusLabel.stringValue). Score \(game.score). Best \(highScore.value).")
    }

    func windowDidResignKey(_ notification: Notification) {
        if game.phase == .running { game.togglePause(); refresh(); scheduleTick() }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate() }
}
