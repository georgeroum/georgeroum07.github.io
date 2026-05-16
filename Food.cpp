#include "Food.h"

#include <random>
#include <utility>

namespace {
constexpr int kBoardWidth = 20;
constexpr int kBoardHeight = 20;

// Centralized "generate new position" logic for a fixed 20x20 board.
std::pair<int, int> generateNewPosition() {
    static std::mt19937 rng(std::random_device{}());
    std::uniform_int_distribution<int> xDistribution(0, kBoardWidth - 1);
    std::uniform_int_distribution<int> yDistribution(0, kBoardHeight - 1);
    return {xDistribution(rng), yDistribution(rng)};
}
}  // namespace

Food::Food() : xPosition(0), yPosition(0) {
    // Spawn food immediately at a valid random cell.
    generateRandomPosition(kBoardWidth, kBoardHeight);
}

void Food::generateRandomPosition(int maxX, int maxY) {
    // Keep the food strictly on a 20x20 board regardless of external values.
    (void)maxX;
    (void)maxY;

    const std::pair<int, int> newPosition = generateNewPosition();
    xPosition = newPosition.first;
    yPosition = newPosition.second;
}

int Food::getXPosition() const {
    return xPosition;
}

int Food::getYPosition() const {
    return yPosition;
}

std::pair<int, int> Food::getPosition() const {
    return {xPosition, yPosition};
}
