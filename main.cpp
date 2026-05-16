#include <SFML/Graphics.hpp>

#include <array>
#include <optional>
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

#if SFML_VERSION_MAJOR >= 3
constexpr sf::Keyboard::Key kKeyUpW = sf::Keyboard::Key::W;
constexpr sf::Keyboard::Key kKeyUpArrow = sf::Keyboard::Key::Up;
constexpr sf::Keyboard::Key kKeyDownS = sf::Keyboard::Key::S;
constexpr sf::Keyboard::Key kKeyDownArrow = sf::Keyboard::Key::Down;
constexpr sf::Keyboard::Key kKeyLeftA = sf::Keyboard::Key::A;
constexpr sf::Keyboard::Key kKeyLeftArrow = sf::Keyboard::Key::Left;
constexpr sf::Keyboard::Key kKeyRightD = sf::Keyboard::Key::D;
constexpr sf::Keyboard::Key kKeyRightArrow = sf::Keyboard::Key::Right;
constexpr sf::Keyboard::Key kKeyRestart = sf::Keyboard::Key::R;
constexpr sf::Keyboard::Key kKeyExit = sf::Keyboard::Key::Escape;
constexpr sf::PrimitiveType kLinePrimitive = sf::PrimitiveType::Lines;
#else
constexpr sf::Keyboard::Key kKeyUpW = sf::Keyboard::W;
constexpr sf::Keyboard::Key kKeyUpArrow = sf::Keyboard::Up;
constexpr sf::Keyboard::Key kKeyDownS = sf::Keyboard::S;
constexpr sf::Keyboard::Key kKeyDownArrow = sf::Keyboard::Down;
constexpr sf::Keyboard::Key kKeyLeftA = sf::Keyboard::A;
constexpr sf::Keyboard::Key kKeyLeftArrow = sf::Keyboard::Left;
constexpr sf::Keyboard::Key kKeyRightD = sf::Keyboard::D;
constexpr sf::Keyboard::Key kKeyRightArrow = sf::Keyboard::Right;
constexpr sf::Keyboard::Key kKeyRestart = sf::Keyboard::R;
constexpr sf::Keyboard::Key kKeyExit = sf::Keyboard::Escape;
constexpr sf::PrimitiveType kLinePrimitive = sf::Lines;
#endif

bool loadFontFromPath(sf::Font& font, const std::string& path) {
#if SFML_VERSION_MAJOR >= 3
    return font.openFromFile(path);
#else
    return font.loadFromFile(path);
#endif
}

void handleInput(const sf::Keyboard::Key key, Game& game) {
    if (key == kKeyUpW || key == kKeyUpArrow) {
        game.changeSnakeDirection(Snake::Direction::Up);
    } else if (key == kKeyDownS || key == kKeyDownArrow) {
        game.changeSnakeDirection(Snake::Direction::Down);
    } else if (key == kKeyLeftA || key == kKeyLeftArrow) {
        game.changeSnakeDirection(Snake::Direction::Left);
    } else if (key == kKeyRightD || key == kKeyRightArrow) {
        game.changeSnakeDirection(Snake::Direction::Right);
    }
}
}  // namespace

int main() {
    const int windowWidth = kBoardWidth * kCellSize;
    const int windowHeight = kHudHeight + kBoardHeight * kCellSize;

#if SFML_VERSION_MAJOR >= 3
    sf::RenderWindow window(
        sf::VideoMode({static_cast<unsigned int>(windowWidth), static_cast<unsigned int>(windowHeight)}),
        "Snake (SFML)"
    );
#else
    sf::RenderWindow window(
        sf::VideoMode(windowWidth, windowHeight),
        "Snake (SFML)"
    );
#endif
    window.setFramerateLimit(60);

    Game game;
    game.startGame();

    sf::Font font;
    bool hasFont = false;
    const std::array<std::string, 5> fontPaths = {
        "DejaVuSans.ttf",
        "arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf"
    };
    for (const std::string& path : fontPaths) {
        if (loadFontFromPath(font, path)) {
            hasFont = true;
            break;
        }
    }

#if SFML_VERSION_MAJOR >= 3
    sf::Text scoreText(font);
    sf::Text gameOverText(font);
#else
    sf::Text scoreText;
    sf::Text gameOverText;
    scoreText.setFont(font);
    gameOverText.setFont(font);
#endif
    scoreText.setCharacterSize(24);
    scoreText.setFillColor(sf::Color::White);
    scoreText.setPosition(10.f, 10.f);

    gameOverText.setCharacterSize(22);
    gameOverText.setFillColor(sf::Color::Red);
    gameOverText.setString("Game Over - Press R to restart");
    gameOverText.setPosition(180.f, 12.f);

    sf::RectangleShape tile(sf::Vector2f(
        static_cast<float>(kCellSize - 2),
        static_cast<float>(kCellSize - 2)
    ));

    sf::Clock clock;
    while (window.isOpen()) {
#if SFML_VERSION_MAJOR >= 3
        while (const std::optional<sf::Event> event = window.pollEvent()) {
            if (event->is<sf::Event::Closed>()) {
                window.close();
            }

            if (const sf::Event::KeyPressed* keyEvent = event->getIf<sf::Event::KeyPressed>()) {
                if (keyEvent->code == kKeyExit) {
                    window.close();
                }

                if (keyEvent->code == kKeyRestart && game.isGameOver()) {
                    game.resetGame();
                    clock.restart();
                }

                if (!game.isGameOver()) {
                    handleInput(keyEvent->code, game);
                }
            }
        }
#else
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed) {
                window.close();
            }

            if (event.type == sf::Event::KeyPressed) {
                if (event.key.code == kKeyExit) {
                    window.close();
                }

                if (event.key.code == kKeyRestart && game.isGameOver()) {
                    game.resetGame();
                    clock.restart();
                }

                if (!game.isGameOver()) {
                    handleInput(event.key.code, game);
                }
            }
        }
#endif

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
            window.draw(line, 2, kLinePrimitive);
        }

        // Draw horizontal grid lines.
        for (int y = 0; y <= kBoardHeight; ++y) {
            const float yPos = static_cast<float>(kHudHeight + y * kCellSize);
            sf::Vertex line[] = {
                sf::Vertex(sf::Vector2f(0.f, yPos), sf::Color(70, 70, 70)),
                sf::Vertex(sf::Vector2f(static_cast<float>(kBoardWidth * kCellSize), yPos), sf::Color(70, 70, 70))
            };
            window.draw(line, 2, kLinePrimitive);
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
