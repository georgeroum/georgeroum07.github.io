#ifndef SNAKE_H
#define SNAKE_H

#include <queue>
#include <utility>

class Snake {
public:
    enum class Direction {
        Up,
        Down,
        Left,
        Right
    };

    Snake();

    void move();
    void grow();
    void changeDirection(Direction newDirection);
    bool checkSelfCollision();

    bool isAlive() const;
    std::pair<int, int> getHeadPosition() const;
    const std::queue<std::pair<int, int>>& getBody() const;

private:
    std::queue<std::pair<int, int>> body;
    std::pair<int, int> headPosition;
    Direction currentDirection;
    bool alive;
};

#endif  // SNAKE_H
