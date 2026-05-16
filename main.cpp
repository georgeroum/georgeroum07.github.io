#include <SFML/Graphics.hpp>

#include <queue>
#include <string>
#include <utility>

#include "Game.h"

namespace {
constexpr int kBoardWidth = 20;
constexpr int kBoardHeight = 20;
constexpr int kCellSize = 30;
constexpr int kHudHeight = 60;
constexpr float kStepSeconds = 0.12f;

void handleInput(const sf::Keyboard::Key key, Game& game) {
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
    const int windowHeight = kHudHeight + kBoardHeight * kCellSize;

    sf::RenderWindow window(
        sf::VideoMode(windowWidth, windowHeight),
        "Snake (SFML)"
    );
    window.setFramerateLimit(60);

    Game game;
    game.startGame();

    sf::Font font;
    bool hasFont = font.loadFromFile("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf");

    sf::Text scoreText;
    sf::Text gameOverText;
    if (hasFont) {
        scoreText.setFont(font);
        scoreText.setCharacterSize(24);
        scoreText.setFillColor(sf::Color::White);
        scoreText.setPosition(10.f, 10.f);

        gameOverText.setFont(font);
        gameOverText.setCharacterSize(22);
        gameOverText.setFillColor(sf::Color::Red);
        gameOverText.setString("Game Over - Press R to restart");
        gameOverText.setPosition(180.f, 12.f);
    }

    sf::RectangleShape tile(sf::Vector2f(
        static_cast<float>(kCellSize - 2),
        static_cast<float>(kCellSize - 2)
    ));

    sf::Clock clock;
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

                if (event.key.code == sf::Keyboard::R && game.isGameOver()) {
                    game.resetGame();
                    clock.restart();
                }

                if (!game.isGameOver()) {
                    handleInput(event.key.code, game);
                }
            }
        }

        if (!game.isGameOver() && clock.getElapsedTime().asSeconds() >= kStepSeconds) {
            game.updateGame();
            clock.restart();
        }

        window.clear(sf::Color(20, 20, 20));

        // Draw vertical grid lines.
        for (int x = 0; x <= kBoardWidth; ++x) {
            const float xPos = static_cast<float>(x * kCellSize);
            sf::Vertex line[] = {
                sf::Vertex(sf::Vector2f(xPos, static_cast<float>(kHudHeight)), sf::Color(70, 70, 70)),
                sf::Vertex(sf::Vector2f(xPos, static_cast<float>(kHudHeight + kBoardHeight * kCellSize)), sf::Color(70, 70, 70))
            };
            window.draw(line, 2, sf::Lines);
        }

        // Draw horizontal grid lines.
        for (int y = 0; y <= kBoardHeight; ++y) {
            const float yPos = static_cast<float>(kHudHeight + y * kCellSize);
            sf::Vertex line[] = {
                sf::Vertex(sf::Vector2f(0.f, yPos), sf::Color(70, 70, 70)),
                sf::Vertex(sf::Vector2f(static_cast<float>(kBoardWidth * kCellSize), yPos), sf::Color(70, 70, 70))
            };
            window.draw(line, 2, sf::Lines);
        }

        // Draw snake.
        std::queue<std::pair<int, int>> body = game.getSnake().getBody();
        tile.setFillColor(sf::Color(60, 200, 60));
        while (!body.empty()) {
            const std::pair<int, int> segment = body.front();
            body.pop();
            tile.setPosition(
                static_cast<float>(segment.first * kCellSize + 1),
                static_cast<float>(kHudHeight + segment.second * kCellSize + 1)
            );
            window.draw(tile);
        }

        // Draw food.
        const std::pair<int, int> foodPos = game.getFood().getPosition();
        tile.setFillColor(sf::Color(230, 70, 70));
        tile.setPosition(
            static_cast<float>(foodPos.first * kCellSize + 1),
            static_cast<float>(kHudHeight + foodPos.second * kCellSize + 1)
        );
        window.draw(tile);

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
