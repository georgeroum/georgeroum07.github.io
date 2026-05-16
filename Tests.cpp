#include <iostream>
#include <string>
#include <utility>

#include "Food.h"
#include "Game.h"
#include "Snake.h"

namespace {
void runTest(const std::string& testName, bool condition, int& passed, int& failed) {
    if (condition) {
        std::cout << "[PASS] " << testName << '\n';
        ++passed;
    } else {
        std::cout << "[FAIL] " << testName << '\n';
        ++failed;
    }
}

bool isInsideBoard(const std::pair<int, int>& position) {
    return position.first >= 0 && position.first < 20 &&
           position.second >= 0 && position.second < 20;
}
}  // namespace

int runSnakeTests() {
    int passed = 0;
    int failed = 0;

    // Test 1: Creating a Snake object.
    Snake snake;
    runTest("Create Snake object", snake.isAlive() && !snake.getBody().empty(), passed, failed);

    // Test 2: Moving the snake should move head forward one cell (default right).
    const std::pair<int, int> snakeHeadBeforeMove = snake.getHeadPosition();
    const std::size_t snakeSizeBeforeMove = snake.getBody().size();
    snake.move();
    const std::pair<int, int> snakeHeadAfterMove = snake.getHeadPosition();
    const bool movedForward =
        snakeHeadAfterMove.first == snakeHeadBeforeMove.first + 1 &&
        snakeHeadAfterMove.second == snakeHeadBeforeMove.second &&
        snake.getBody().size() == snakeSizeBeforeMove;
    runTest("Move Snake", movedForward, passed, failed);

    // Test 3: Changing direction to up should affect the next move.
    Snake directionSnake;
    directionSnake.changeDirection(Snake::Direction::Up);
    directionSnake.move();
    runTest(
        "Change Snake direction",
        directionSnake.getHeadPosition() == std::make_pair(5, 4),
        passed,
        failed
    );

    // Test 4: Creating a Food object.
    Food food;
    runTest("Create Food object", isInsideBoard(food.getPosition()), passed, failed);

    // Test 5: Generating a new food position should keep it inside 20x20 board.
    food.generateRandomPosition(20, 20);
    runTest("Generate new Food position", isInsideBoard(food.getPosition()), passed, failed);

    // Test 6: Creating a Game object.
    Game game;
    runTest("Create Game object", game.getSnake().isAlive(), passed, failed);

    // Test 7: Score starts at 0.
    runTest("Game score starts at 0", game.getScore() == 0, passed, failed);

    // Test 8: gameOver starts false.
    runTest("Game gameOver starts false", !game.isGameOver(), passed, failed);

    std::cout << "\nTotal Passed: " << passed << '\n';
    std::cout << "Total Failed: " << failed << '\n';

    return failed == 0 ? 0 : 1;
}

#ifdef RUN_SNAKE_TESTS
int main() {
    return runSnakeTests();
}
#endif
