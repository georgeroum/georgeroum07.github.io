#include "Game.h"

#include <queue>
#include <utility>

namespace {
bool isOnSnake(const Snake& snake, const std::pair<int, int>& position) {
    std::queue<std::pair<int, int>> bodyCopy = snake.getBody();
    while (!bodyCopy.empty()) {
        if (bodyCopy.front() == position) {
            return true;
        }
        bodyCopy.pop();
    }
    return false;
}

// Predict the next head cell from the last two body segments.
// Body queue order is tail -> head, so the final two elements
// reveal the current movement vector.
std::pair<int, int> predictNextHead(const Snake& snake) {
    const std::pair<int, int> head = snake.getHeadPosition();
    std::queue<std::pair<int, int>> bodyCopy = snake.getBody();

    if (bodyCopy.size() < 2) {
        // Fallback if body is unexpectedly short.
        return {head.first + 1, head.second};
    }

    std::pair<int, int> secondToLast = bodyCopy.front();
    std::pair<int, int> last = bodyCopy.front();
    while (!bodyCopy.empty()) {
        secondToLast = last;
        last = bodyCopy.front();
        bodyCopy.pop();
    }

    const int dx = last.first - secondToLast.first;
    const int dy = last.second - secondToLast.second;
    return {head.first + dx, head.second + dy};
}

void respawnFoodNotOnSnake(Food& food, const Snake& snake, int boardWidth, int boardHeight) {
    // Keep trying random cells until we find one not occupied by the snake.
    // The attempt cap prevents an infinite loop if the board becomes very full.
    const int maxAttempts = boardWidth * boardHeight * 2;
    for (int attempt = 0; attempt < maxAttempts; ++attempt) {
        food.generateRandomPosition(boardWidth, boardHeight);
        if (!isOnSnake(snake, food.getPosition())) {
            return;
        }
    }
}
}  // namespace

Game::Game()
    : snake(), food(), score(0), gameOver(false), boardWidth(20), boardHeight(20) {
    respawnFoodNotOnSnake(food, snake, boardWidth, boardHeight);
}

void Game::startGame() {
    // Start from a clean state.
    resetGame();
}

void Game::updateGame() {
    if (gameOver) {
        return;
    }

    // Check whether the next step reaches food.
    // If yes, grow (which keeps the tail) and award score.
    // If no, do a normal move (push head + pop tail).
    checkFoodCollision();

    // After movement, verify wall and self collisions.
    checkWallCollision();
    if (snake.checkSelfCollision()) {
        gameOver = true;
    }
}

void Game::checkFoodCollision() {
    if (gameOver) {
        return;
    }

    const std::pair<int, int> nextHead = predictNextHead(snake);
    const std::pair<int, int> foodPosition = food.getPosition();

    if (nextHead == foodPosition) {
        ++score;
        snake.grow();
        respawnFoodNotOnSnake(food, snake, boardWidth, boardHeight);
    } else {
        snake.move();
    }
}

void Game::checkWallCollision() {
    const std::pair<int, int> head = snake.getHeadPosition();

    if (head.first < 0 || head.first >= boardWidth ||
        head.second < 0 || head.second >= boardHeight) {
        gameOver = true;
    }
}

void Game::resetGame() {
    snake = Snake();
    food = Food();
    score = 0;
    gameOver = false;

    // Ensure food is not placed on top of the reset snake body.
    respawnFoodNotOnSnake(food, snake, boardWidth, boardHeight);
}

int Game::getScore() const {
    return score;
}

bool Game::isGameOver() const {
    return gameOver;
}

void Game::changeSnakeDirection(Snake::Direction newDirection) {
    if (!gameOver) {
        snake.changeDirection(newDirection);
    }
}

const Snake& Game::getSnake() const {
    return snake;
}

const Food& Game::getFood() const {
    return food;
}
