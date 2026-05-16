#ifndef GAME_H
#define GAME_H

#include "Food.h"
#include "Snake.h"

class Game {
public:
    Game();

    void startGame();
    void updateGame();
    void checkFoodCollision();
    void checkWallCollision();
    void resetGame();

    int getScore() const;
    bool isGameOver() const;
    void changeSnakeDirection(Snake::Direction newDirection);
    const Snake& getSnake() const;
    const Food& getFood() const;

private:
    Snake snake;
    Food food;
    int score;
    bool gameOver;
    int boardWidth;
    int boardHeight;
};

#endif  // GAME_H
