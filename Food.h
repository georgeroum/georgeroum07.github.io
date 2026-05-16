#ifndef FOOD_H
#define FOOD_H

#include <utility>

class Food {
public:
    Food();

    void generateRandomPosition(int maxX, int maxY);

    int getXPosition() const;
    int getYPosition() const;
    std::pair<int, int> getPosition() const;

private:
    int xPosition;
    int yPosition;
};

#endif  // FOOD_H
