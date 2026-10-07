import Foundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    guard condition() else { fatalError("FAIL: \(message)") }
}

var game = SnakeGame(columns: 6, rows: 6, chooseIndex: { _ in 19 })
expect(game.phase == .ready && game.snake.count == 3, "initial state")
let initial = game.snake
game.tick()
expect(game.snake == initial, "ready does not move")
game.start()
expect(game.food == Cell(x: 4, y: 3), "deterministic food outside snake")
game.turn(.left)
game.tick()
expect(game.direction == .right, "reverse direction rejected")
expect(game.snake.first == Cell(x: 4, y: 3), "exactly one cell per tick")
expect(game.snake.count == 4 && game.score == 10, "eating grows and scores")
expect(game.tickInterval < 0.17, "speed increases")
game.tick()
expect(game.snake.count == 5 && game.score == 20, "consecutive growth")
game.turn(.down); game.tick()
game.turn(.left); game.tick()
game.turn(.up); game.tick()
expect(game.phase == .gameOver, "self collision ends game")
let dead = game.snake
game.tick()
expect(game.snake == dead, "game over stops movement")
game.start()
expect(game.score == 0 && game.snake.count == 3 && game.phase == .running, "restart resets game")
game.togglePause()
let paused = game.snake
game.turn(.up)
game.tick()
expect(game.phase == .paused && game.snake == paused, "paused input and ticks cannot move snake")
game.togglePause()
game.tick()
expect(game.phase == .running && game.snake != paused, "resume moves again")
game.tick(); game.tick()
expect(game.phase == .gameOver, "right wall collision")

for direction in [Direction.up, .down, .left] {
    var wall = SnakeGame(columns: 6, rows: 6, chooseIndex: { _ in 0 })
    wall.start()
    if direction == .left { wall.turn(.up); wall.tick() }
    wall.turn(direction)
    for _ in 0..<8 { wall.tick() }
    expect(wall.phase == .gameOver, "wall collision: \(direction)")
}

var buffered = SnakeGame(columns: 6, rows: 6, chooseIndex: { _ in 0 })
buffered.start()
buffered.turn(.up)
buffered.turn(.left)
buffered.turn(.down) // Buffer accepts only two turns.
buffered.tick()
expect(buffered.snake.first == Cell(x: 3, y: 2), "first buffered turn")
buffered.tick()
expect(buffered.snake.first == Cell(x: 2, y: 2), "second buffered turn on separate tick")
buffered.tick()
expect(buffered.snake.first == Cell(x: 1, y: 2), "excess buffered input discarded")

// A four-segment snake may move into the cell its tail vacates.
var tail = SnakeGame(columns: 6, rows: 6, chooseIndex: { _ in 19 })
tail.start(); tail.tick()
tail.turn(.down); tail.tick()
tail.turn(.left); tail.tick()
tail.turn(.up); tail.tick()
expect(tail.phase == .running && tail.snake.first == Cell(x: 3, y: 3), "vacating tail cell is legal")

for _ in 0..<300 {
    let random = SnakeGame()
    expect(random.food != nil && !random.snake.contains(random.food!), "random food avoids body")
}

// Follow a Hamiltonian cycle until every cell is filled. This exercises every
// food placement, repeated growth, speed floor, and the full-board win state.
var full = SnakeGame(columns: 6, rows: 6, chooseIndex: { _ in 0 })
full.start()
var route: [Cell] = []
for x in 0..<6 { route.append(Cell(x: x, y: 0)) }
for y in 1..<6 {
    let xs = y % 2 == 1 ? Array((1..<6).reversed()) : Array(1..<6)
    for x in xs { route.append(Cell(x: x, y: y)) }
}
for y in (1..<6).reversed() { route.append(Cell(x: 0, y: y)) }
// Reverse the cycle to match the initial right-facing snake on row 3.
route.reverse()
for _ in 0..<2000 {
    if full.phase != .running { break }
    let head = full.snake[0]
    let index = route.firstIndex(of: head)!
    let next = route[(index + 1) % route.count]
    let dx = next.x - head.x, dy = next.y - head.y
    full.turn(dx == 1 ? .right : dx == -1 ? .left : dy == 1 ? .down : .up)
    full.tick()
    if let food = full.food { expect(!full.snake.contains(food), "food avoids growing body") }
}
expect(full.phase == .won && full.food == nil && full.snake.count == 36, "full board wins without spawn loop")
expect(full.score == 330 && full.tickInterval == 0.065, "final score and speed floor")

let suite = "SnakeTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
let store = HighScoreStore(defaults: defaults)
store.record(40)
store.record(10)
expect(store.value == 40, "high score never decreases")
let reopened = HighScoreStore(defaults: UserDefaults(suiteName: suite)!)
expect(reopened.value == 40, "high score persists across store recreation")
defaults.removePersistentDomain(forName: suite)
print("PASS: \(checks) checks — movement, input queue, food, growth, scoring, speed, walls, self collision, tail, pause, restart, win, persistence")
