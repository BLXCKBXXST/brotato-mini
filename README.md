# 🥔 Brotato Mini

Мини-игра в стиле [Brotato](https://store.steampowered.com/app/1942280/Brotato/), написанная на **Godot 4 + GDScript**.

## Геймплей

- **20 волн** нарастающей сложности
- **Авто-стрельба** по ближайшему врагу в радиусе
- **4 типа врагов**: слизень, летучая мышь, камень, элита (с волны 5)
- **Магазин** между волнами — 4 случайных предмета
- **XP + уровни** — повышение максимального HP
- **Дроп материалов** — притягиваются к игроку

## Управление

| Клавиши | Действие |
|---|---|
| `WASD` / Стрелки | Движение |
| — | Авто-стрельба |

## Установка и запуск

### 1. Установить Godot 4

Скачай **Godot Engine 4.x** (Standard, не .NET) с официального сайта:
👉 https://godotengine.org/download

Для Windows: скачай `.exe`, распакуй в папку, запусти — установка не нужна.

### 2. Открыть проект

```bash
git clone https://github.com/BLXCKBXXST/brotato-mini.git
```

Затем в Godot: **Import** → выбери папку `brotato-mini` → **Import & Edit**.

### 3. Запустить

Нажми **F5** или кнопку ▶ в редакторе.

## Структура проекта

```
brotato-mini/
├── project.godot          # Конфиг проекта
├── scenes/
│   ├── Main.tscn          # Корневая сцена
│   ├── Enemy.tscn         # Враг
│   ├── Bullet.tscn        # Снаряд
│   ├── Drop.tscn          # Дроп материалов
│   └── FloatText.tscn     # Плавающий текст урона
└── scripts/
    ├── GameManager.gd     # Синглтон (авто-загрузка)
    ├── Main.gd            # Контроллер игры
    ├── Player.gd          # Движение + авто-стрельба
    ├── Enemy.gd           # AI врага
    ├── Bullet.gd          # Логика снаряда
    ├── Drop.gd            # Притяжение дропа
    ├── WaveManager.gd     # Спавн волн
    ├── Shop.gd            # Магазин
    ├── HUD.gd             # Интерфейс боя
    └── FloatText.gd       # Текст урона
```

## Дорожная карта (TODO)

- [ ] Спрайты вместо ColorRect
- [ ] Звуки и музыка
- [ ] Больше типов врагов
- [ ] Больше предметов (15+)
- [ ] Разные персонажи с уникальными способностями
- [ ] Сохранение рекордов
- [ ] Экспорт на Android
- [ ] Босс на волне 10 и 20

## Экспорт на Android

1. Установи **Android Build Template** в Godot: `Project → Export → Add → Android`
2. Скачай Android SDK и укажи путь в настройках Godot
3. Нажми **Export Project** → получи `.apk`

> Подробнее: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
