#include "Snake.h"

namespace {
std::pair<int, int> computeNextHead(
    const std::pair<int, int>& currentHead,
    Snake::Direction direction
) {
    std::pair<int, int> nextHead = currentHead;

    switch (direction) {
        case Snake::Direction::Up:
            --nextHead.second;
            break;
        case Snake::Direction::Down:
            ++nextHead.second;
            break;
        case Snake::Direction::Left:
            --nextHead.first;
            break;
        case Snake::Direction::Right:
            ++nextHead.first;
            break;
    }

    return nextHead;
}

bool isOppositeDirection(Snake::Direction a, Snake::Direction b) {
    return (a == Snake::Direction::Up && b == Snake::Direction::Down) ||
           (a == Snake::Direction::Down && b == Snake::Direction::Up) ||
           (a == Snake::Direction::Left && b == Snake::Direction::Right) ||
           (a == Snake::Direction::Right && b == Snake::Direction::Left);
}
}  // namespace

Snake::Snake()
    : headPosition({5, 5}), currentDirection(Direction::Right), alive(true) {
    // Queue order is tail -> head.
    // This starts a 3-segment snake ending at headPosition.
    body.push({3, 5});
    body.push({4, 5});
    body.push({5, 5});
}

void Snake::move() {
    if (!alive) {
        return;
    }

    const std::pair<int, int> nextHead = computeNextHead(headPosition, currentDirection);

    // Normal movement with a queue:
    // 1) push the new head to the back
    // 2) pop the oldest element from the front (old tail)
    // Net result: length stays the same while position advances.
    body.push(nextHead);
    body.pop();
    headPosition = nextHead;
}

void Snake::grow() {
    if (!alive) {
        return;
    }

    const std::pair<int, int> nextHead = computeNextHead(headPosition, currentDirection);

    // Growth movement with a queue:
    // push new head but DO NOT pop the tail.
    // Net result: snake length increases by 1.
    body.push(nextHead);
    headPosition = nextHead;
}

void Snake::changeDirection(Direction newDirection) {
    // Ignore 180-degree turns so the snake cannot reverse into itself in one step.
    if (isOppositeDirection(currentDirection, newDirection)) {
        return;
    }

    currentDirection = newDirection;
}

bool Snake::checkSelfCollision() {
    if (body.empty()) {
        return false;
    }

    // std::queue has no iterators, so copy and pop through it.
    // We compare headPosition against every segment except the last queue item,
    // because the last item is the current head itself.
    std::queue<std::pair<int, int>> segments = body;
    while (segments.size() > 1) {
        if (segments.front() == headPosition) {
            alive = false;
            return true;
        }
        segments.pop();
    }

    return false;
}

bool Snake::isAlive() const {
    return alive;
}

std::pair<int, int> Snake::getHeadPosition() const {
    return headPosition;
}

const std::queue<std::pair<int, int>>& Snake::getBody() const {
    return body;
}
