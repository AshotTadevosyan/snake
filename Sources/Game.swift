import Foundation

struct Cell: Equatable, Hashable {
    let x: Int
    let y: Int
}

enum Direction {
    case up, down, left, right

    var offset: (Int, Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }

    func isOpposite(to other: Direction) -> Bool {
        let a = offset, b = other.offset
        return a.0 + b.0 == 0 && a.1 + b.1 == 0
    }
}

enum GamePhase { case ready, running, paused, gameOver, won }

final class HighScoreStore {
    private let defaults: UserDefaults
    private let key = "snake.highScore"
    var value: Int { defaults.integer(forKey: key) }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func record(_ score: Int) {
        if score > value { defaults.set(score, forKey: key) }
    }
}

struct SnakeGame {
    let columns: Int
    let rows: Int
    private(set) var snake: [Cell] = []
    private(set) var food: Cell?
    private(set) var direction: Direction = .right
    private(set) var phase: GamePhase = .ready
    private(set) var score = 0
    private var turns: [Direction] = []
    private let chooseIndex: (Int) -> Int

    var level: Int { score / 50 + 1 }
    var tickInterval: TimeInterval { max(0.065, 0.17 - Double(score / 10) * 0.004) }

    init(columns: Int = 24, rows: Int = 20,
         chooseIndex: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        precondition(columns >= 6 && rows >= 6)
        self.columns = columns
        self.rows = rows
        self.chooseIndex = chooseIndex
        reset()
    }

    mutating func reset() {
        let x = columns / 2, y = rows / 2
        snake = [Cell(x: x, y: y), Cell(x: x - 1, y: y), Cell(x: x - 2, y: y)]
        direction = .right
        turns = []
        score = 0
        phase = .ready
        placeFood()
    }

    mutating func start() { reset(); phase = .running }

    mutating func togglePause() {
        if phase == .running { phase = .paused }
        else if phase == .paused { phase = .running }
    }

    mutating func turn(_ next: Direction) {
        guard phase == .running, turns.count < 2 else { return }
        let previous = turns.last ?? direction
        guard next != previous, !next.isOpposite(to: previous) else { return }
        turns.append(next)
    }

    mutating func tick() {
        guard phase == .running, let head = snake.first else { return }
        if !turns.isEmpty { direction = turns.removeFirst() }
        let delta = direction.offset
        let next = Cell(x: head.x + delta.0, y: head.y + delta.1)
        let eats = next == food
        // The tail leaves its cell on this tick, unless food causes growth.
        let occupied = eats ? snake : Array(snake.dropLast())
        guard next.x >= 0, next.x < columns, next.y >= 0, next.y < rows,
              !occupied.contains(next) else {
            phase = .gameOver
            turns = []
            return
        }
        snake.insert(next, at: 0)
        if eats {
            score += 10
            placeFood()
        } else {
            snake.removeLast()
        }
    }

    private mutating func placeFood() {
        let occupied = Set(snake)
        var available: [Cell] = []
        for y in 0..<rows {
            for x in 0..<columns {
                let cell = Cell(x: x, y: y)
                if !occupied.contains(cell) { available.append(cell) }
            }
        }
        guard !available.isEmpty else { food = nil; phase = .won; return }
        food = available[chooseIndex(available.count)]
    }
}
