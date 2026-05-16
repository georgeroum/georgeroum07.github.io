#include <SFML/Graphics.hpp>

#include <iostream>
#include <queue>
#include <string>
#include <utility>

#include "Game.h"

namespace {
constexpr int kBoardWidth = 20;
constexpr int kBoardHeight = 20;
constexpr int kCellSize = 30;
constexpr int kHudHeight = 60;
constexpr float kUpdateIntervalSeconds = 0.12f;

void handleDirectionInput(const sf::Keyboard::Key key, Game& game) {
    if (key == sf::Keyboard::W || key == sf::Keyboard::Up) {
        game.changeSnakeDirection(Snake::Direction::Up);
    } else if (key == sf::Keyboard::S || key == sf::Keyboard::Down) {
        game.changeSnakeDirection(Snake::Direction::Down);
    } else if (key == sf::Keyboard::A || key == sf::Keyboard::Left) {
        game.changeSnakeDirection(Snake::Direction::Left);
    } else if (key == sf::Keyboard::D || key == sf::Keyboard::Right) {
        game.changeSnakeDirection(Snake::Direction::Right);
    }
}
}  // namespace

int main() {
    const int windowWidth = kBoardWidth * kCellSize;
    const int windowHeight = kBoardHeight * kCellSize + kHudHeight;

    sf::RenderWindow window(
        sf::VideoMode(windowWidth, windowHeight),
        "Snake - SFML"
    );
    window.setFramerateLimit(60);

    Game game;
    game.startGame();

    // Try common font locations across Linux/Windows/macOS.
    // If none is found, the game still runs (without text rendering).
    sf::Font font;
    bool hasFont = false;
    const std::string fontPaths[] = {
        "DejaVuSans.ttf",
        "arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf"
    };
    for (const std::string& path : fontPaths) {
        if (font.loadFromFile(path)) {
            hasFont = true;
            break;
        }
    }
    if (!hasFont) {
        std::cerr << "Warning: no font found; score text will be hidden.\n";
    }

    sf::Text scoreText;
    if (hasFont) {
        scoreText.setFont(font);
        scoreText.setCharacterSize(24);
        scoreText.setFillColor(sf::Color::White);
        scoreText.setPosition(10.f, 12.f);
    }

    sf::Text gameOverText;
    if (hasFont) {
        gameOverText.setFont(font);
        gameOverText.setCharacterSize(24);
        gameOverText.setFillColor(sf::Color::Red);
        gameOverText.setString("Game Over - Press R to restart");
        gameOverText.setPosition(110.f, 12.f);
    }

    // Reused rectangle for drawing snake and food cells.
    sf::RectangleShape cellShape(sf::Vector2f(
        static_cast<float>(kCellSize - 2),
        static_cast<float>(kCellSize - 2)
    ));

    sf::Clock updateClock;

    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed) {
                window.close();
            }

            if (event.type == sf::Event::KeyPressed) {
                if (event.key.code == sf::Keyboard::Escape) {
                    window.close();
                }

                // Restart only after a loss, as requested.
                if (event.key.code == sf::Keyboard::R && game.isGameOver()) {
                    game.resetGame();
                    updateClock.restart();
                }

                if (!game.isGameOver()) {
                    handleDirectionInput(event.key.code, game);
                }
            }
        }

        // Advance game logic at a fixed interval to control snake speed.
        if (!game.isGameOver() &&
            updateClock.getElapsedTime().asSeconds() >= kUpdateIntervalSeconds) {
            game.updateGame();
            updateClock.restart();
        }

        window.clear(sf::Color(20, 20, 20));

        // Draw the 20x20 board grid.
        for (int x = 0; x <= kBoardWidth; ++x) {
            sf::Vertex line[] = {
                sf::Vertex(
                    sf::Vector2f(static_cast<float>(x * kCellSize), static_cast<float>(kHudHeight)),
                    sf::Color(70, 70, 70)
                ),
                sf::Vertex(
                    sf::Vector2f(static_cast<float>(x * kCellSize), static_cast<float>(kHudHeight + kBoardHeight * kCellSize)),
                    sf::Color(70, 70, 70)
                )
            };
            window.draw(line, 2, sf::Lines);
        }
        for (int y = 0; y <= kBoardHeight; ++y) {
            sf::Vertex line[] = {
                sf::Vertex(
                    sf::Vector2f(0.f, static_cast<float>(kHudHeight + y * kCellSize)),
                    sf::Color(70, 70, 70)
                ),
                sf::Vertex(
                    sf::Vector2f(static_cast<float>(kBoardWidth * kCellSize), static_cast<float>(kHudHeight + y * kCellSize)),
                    sf::Color(70, 70, 70)
                )
            };
            window.draw(line, 2, sf::Lines);
        }

        // Draw snake by copying the queue and consuming it front-to-back.
        std::queue<std::pair<int, int>> snakeBody = game.getSnake().getBody();
        cellShape.setFillColor(sf::Color(50, 200, 50));
        while (!snakeBody.empty()) {
            const std::pair<int, int> segment = snakeBody.front();
            snakeBody.pop();

            cellShape.setPosition(
                static_cast<float>(segment.first * kCellSize + 1),
                static_cast<float>(kHudHeight + segment.second * kCellSize + 1)
            );
            window.draw(cellShape);
        }

        // Draw food cell.
        const std::pair<int, int> foodPosition = game.getFood().getPosition();
        cellShape.setFillColor(sf::Color(220, 50, 50));
        cellShape.setPosition(
            static_cast<float>(foodPosition.first * kCellSize + 1),
            static_cast<float>(kHudHeight + foodPosition.second * kCellSize + 1)
        );
        window.draw(cellShape);

        // Draw score and game-over message in the HUD if a font is available.
        if (hasFont) {
            scoreText.setString("Score: " + std::to_string(game.getScore()));
            window.draw(scoreText);
            if (game.isGameOver()) {
                window.draw(gameOverText);
            }
        }

        window.display();
    }

    return 0;
}
