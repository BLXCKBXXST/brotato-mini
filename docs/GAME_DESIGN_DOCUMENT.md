# 🥔 Brotato Mini — Game Design Document

> Подробная документация по всему реализованному на текущий момент.
> Движок: **Godot 4.x** · Язык: **GDScript** · Жанр: **Roguelite Arena Shooter**

---

## 📑 Содержание

1. [Обзор игры](#-обзор-игры)
2. [Структура проекта](#-структура-проекта)
3. [Игровой цикл](#-игровой-цикл)
4. [Арена и камера](#-арена-и-камера)
5. [Игрок](#-игрок)
6. [Система оружий](#-система-оружий)
7. [Враги](#-враги)
8. [Боссы](#-боссы)
9. [Волны](#-волны)
10. [Прогрессия: XP и уровни](#-прогрессия-xp-и-уровни)
11. [Магазин — Оружие](#-магазин--оружие)
12. [Магазин — Прокачка тела](#-магазин--прокачка-тела)
13. [Магазин — Аксессуары](#-магазин--аксессуары)
14. [HUD](#-hud)
15. [Экраны состояний](#-экраны-состояний)
16. [Polish: пауза, shake, частицы, звук](#-polish-пауза-shake-частицы-звук)
17. [Архитектура скриптов](#-архитектура-скриптов)

---

## 🎮 Обзор игры

**Brotato Mini** — это вдохновлённый игрой Brotato arena roguelite с видом сверху. Игрок управляет персонажем на арене 1300×1300 пикселей, выживает через 20 нарастающих волн, между волнами заходит в магазин.

**Цель**: пережить все 20 волн и убить финального босса.

**Ключевые особенности:**
- До 6 weapon-слотов с разными паттернами выстрелов (single / shotgun / sniper / smg)
- Тиры оружий I–IV, комбайн **2 одинаковых tier-N → 1 tier-(N+1)**
- Автоматическая стрельба, каждое оружие со своим cooldown
- 4 типа базовых врагов + 4 босса (волны 5/10/15/20)
- Боссы со способностями: dash, shoot, summon
- Трёхвкладочный магазин: оружия + прокачка тела + аксессуары
- Прокачка тела даёт процентные модификаторы ко всем оружиям
- Пауза по Esc, screen shake, партиклы, процедурный звук

---

## 📁 Структура проекта

```
brotato-mini/
├── project.godot
├── icon.svg
├── docs/
│   └── GAME_DESIGN_DOCUMENT.md
├── scenes/
│   ├── Main.tscn
│   ├── Enemy.tscn
│   ├── Bullet.tscn
│   ├── EnemyBullet.tscn      # снаряд босса-стрелка
│   ├── Drop.tscn
│   ├── FloatText.tscn
│   ├── HitParticle.tscn      # короткоживущие партиклы
│   └── SpawnWarning.tscn
└── scripts/
    ├── GameManager.gd        # autoload: данные игры + weapon API
    ├── AudioBus.gd           # autoload: процедурный звук
    ├── Main.gd               # игровой цикл + пауза + shake
    ├── Player.gd             # движение, стрельба per-weapon
    ├── Enemy.gd              # ИИ врага + boss AI
    ├── EnemyBullet.gd        # снаряд босса
    ├── Bullet.gd             # пуля + партиклы при попадании
    ├── Drop.gd               # дроп материалов
    ├── Shop.gd               # 3-вкладочный магазин
    ├── HUD.gd
    ├── FloatText.gd
    ├── HitParticle.gd        # короткоживущие частицы
    ├── SpawnWarning.gd
    └── WaveManager.gd        # спаун волн + боссов
```

---

## 🔄 Игровой цикл

```
[Титульный экран]
       │
       ▼  кнопка «Начать игру»
[Волна N — Бой]  ←─── Esc → пауза → Esc/«Продолжить»
       │
       ├─ таймер истёк (не-боссовая волна) → [Магазин]
       ├─ босс убит (волны 5/10/15)        → [Магазин]
       ├─ босс убит (волна 20)             → [Экран победы]
       ├─ HP игрока = 0                    → [Game Over]
       │
       │            ↓ «Следующая волна»
       └──────────────[Магазин]
```

Состояния (`GameManager.game_state`): `title / fight / shop / gameover / win`.

---

## 🗺 Арена и камера

- 1300×1300 пикселей, координаты от `(-10, -260)` до `(1290, 1040)`
- Camera2D — дочерний к Player, `position_smoothing_enabled`, лимиты по границам арены
- И игрок, и враги имеют `_clamp_to_arena()`

---

## 🧑 Игрок

### Параметры (`GameManager.player_stats`)

**Базовые статы** (flat):
- `max_hp` (100), `hp`, `armor` (0), `speed` (200.0), `dodge` (0.0), `lifesteal` (0.0)
- `level`, `xp`, `xp_next`, `materials`, `total_kills`, `total_damage`

**Глобальные модификаторы оружий** (применяются ко всем weapons):
- `damage_pct` — % бонус к урону всех оружий
- `attack_speed_pct` — % бонус к скорости атаки
- `range_pct` — % бонус к дальности
- `pierce_bonus` — flat бонус к пробитию

### Управление
- WASD / Стрелки — движение
- **Esc** — пауза
- Стрельба автоматическая, каждое оружие со своим cooldown

### Получение урона
1. Проверка `dodge`: `randf() < dodge → промах`
2. Реальный урон = `max(incoming - armor, 1.0)`
3. Вычет из hp + screen shake (3.0) + звук `player_hurt`
4. `hp <= 0 → GameManager.player_died.emit()`

---

## 🔫 Система оружий

### Слоты
- До `MAX_WEAPON_SLOTS = 6` оружий одновременно
- Стартовое оружие: 1× Пистолет (Tier I)
- Каждое оружие — `{def_id: String, tier: int}` в `GameManager.player_weapons`

### Базовые определения (`GameManager.WEAPON_DEFS`)

| ID | Имя | Паттерн | Base DMG | Base CD | Range | Pierce | Bullets | Spread | Base Cost |
|----|-----|---------|----------|---------|-------|--------|---------|--------|-----------|
| `pistol`  | 🔫 Пистолет | single  | 14  | 0.83 | 240 | 1 | 1 | 0°  | 30 |
| `shotgun` | 💥 Дробовик | shotgun | 8   | 1.40 | 200 | 1 | 5 | 30° | 55 |
| `sniper`  | 🎯 Снайперка | sniper  | 55  | 2.20 | 700 | 4 | 1 | 0°  | 70 |
| `smg`     | 🔫 SMG      | smg     | 5   | 0.20 | 220 | 1 | 1 | 10° | 55 |
| `flamer`  | 🔥 Огнемёт | smg     | 4   | 0.10 | 160 | 3 | 1 | 20° | 60 |
| `minigun` | 🔩 Миниган | smg     | 6   | 0.14 | 260 | 1 | 1 | 6°  | 65 |

### Тиры

| Тир | Множитель урона | Множитель cooldown | Цвет | Множитель цены |
|-----|-----------------|--------------------|------|----------------|
| I   | 1.0             | 1.0                | серый | 1.0  |
| II  | 1.5             | 0.9                | зелёный | 2.0 |
| III | 2.2             | 0.8                | синий | 3.5 |
| IV  | 3.2             | 0.7                | фиолетовый | 6.0 |

**Combine**: 2 одинаковых оружия (тот же `def_id` и `tier`) → 1 на `tier+1`.

### Формула эффективных статов

```
effective_damage   = base_damage * TIER_DAMAGE_MULT[tier-1] * (1 + damage_pct)
effective_cooldown = base_cooldown * TIER_COOLDOWN_MULT[tier-1] / (1 + attack_speed_pct)
effective_range    = base_range * (1 + range_pct)
effective_pierce   = base_pierce + pierce_bonus
```

### Цикл стрельбы (`Player._handle_shooting`)
1. Каждое оружие имеет независимый `weapon_cooldowns[i]`
2. Cooldown тикает на `delta`. При `<= 0` ищет ближайшего врага в своём радиусе
3. Найден → `_fire_weapon` (вызывает паттерн + звук + shake)
4. Не найден → cooldown = 0.1с (повторная проверка)

### Паттерны выстрелов
- **single** (pistol): одна пуля по точному направлению
- **shotgun**: `bullet_count` пуль, равномерно по конусу `spread_deg`
- **sniper**: одна быстрая длинная пуля, повёрнутая по направлению полёта
- **smg / flamer / minigun**: одна пуля с jitter (половина `spread_deg`)

---

## 👾 Враги

### 4 типа

| Тип | Цвет | Base HP | HP/волну | Скорость | Урон | XP | Mat | Доступен |
|-----|------|---------|----------|----------|------|----|----|----------|
| Быстрый | 🟢 | 18 | +5 | 65 | 8 | 3 | 2 | волна 1 |
| Лёгкий  | 🟣 | 10 | +2 | 115 | 5 | 2 | 1 | волна 1 |
| Танк    | ⬜ | 45 | +9 | 38 | 14 | 5 | 4 | волна 1 |
| Элитный | 🔴 | 110 | +22 | 44 | 18 | 14 | 10 | волна 5 |

`hp = base_hp + hp_per_wave × wave`
`speed = base_speed + wave × 2.0`

### ИИ
- `_seek_player()` → нормализованный вектор × speed
- `_check_player_contact()` → урон каждые 0.5с при дистанции < 30 (60 для босса)
- При смерти: партикл цвета врага, звук `enemy_die`, shake 1.0

---

## 💀 Боссы

### Боссовые волны: **5, 10, 15, 20**

| Волна | Способность | HP-мульт | DMG-мульт | XP | Mat | Цвет |
|-------|-------------|----------|-----------|----|----|------|
| 5     | dash        | 20×      | 1.6×      | 40 | 25 | красный |
| 10    | shoot       | 35×      | 1.7×      | 60 | 35 | фиолет |
| 15    | summon      | 55×      | 1.9×      | 90 | 50 | оранж |
| 20    | dash        | 100×     | 2.4×      | 150 | 80 | тёмно-красный (финал) |

**HP формула**: `base_hp(быстрого врага) × hp_mult + wave × 40`

### Способности
- **dash**: рывок к точке за игроком (0.45 сек, цвет меняется на оранжевый). Cooldown 3.5с
- **shoot**: веер из 3 пуль `EnemyBullet` в сторону игрока (urgentscale 0.8×damage). Cooldown 2.0с
- **summon**: 3 быстрых лёгких врага вокруг себя. Cooldown 5.5с

### Спавн
- Волны 5/10/15: босс появляется в середине волны (через `wave_duration × 0.5`)
- Волна 20: босс появляется через 0.5с после старта
- Большой spawn-индикатор (60px), длительность 1.5с

### Окончание боссовой волны
- На таймере wave_timer не закрывается, перезапускается
- Сигнал `GameManager.boss_killed(ability)` → `WaveManager._on_boss_killed`
  - Волна 5/10/15: `wave_ended.emit()` → магазин
  - Волна 20: `game_won.emit()` → экран победы

---

## 🌊 Волны

| Параметр | Формула | Пример (1 / 10 / 20) |
|----------|---------|---------------------|
| Длительность | `min(20 + wave×3, 60)` | 23 / 50 / 60с |
| Spawn-интервал | `max(0.3, 1.2 - wave×0.04)` | 1.16 / 0.80 / 0.40с |
| Врагов/тик | `1 + int(wave / 6)` | 1 / 2 / 4 |

Враги спаунятся вне видимой камеры (через `_random_offscreen_pos`).

---

## ⬆️ Прогрессия: XP и уровни

- `xp_next` стартует с 30, при левелапе `xp_next *= 1.4`
- При левелапе: `max_hp += 5`, `hp += 10`, звук `level_up`

---

## 🔫 Магазин — Оружие

Первая вкладка (открыта при входе в магазин).

### Слоты (верхняя часть)
6 ячеек:
- **Занятая**: имя (цвет тира), `Тир X`, эффективные `dmg/cd/range`, кнопки «Объединить» (если есть пара) и «Продать (50% цены)»
- **Пустая**: серая надпись «— пусто —»

### Предложения к покупке (нижняя часть)
4 случайных оружия из пула. Распределение тиров зависит от волны:
- Волны 1–4: только Tier I
- Волны 5+: 35% шанс Tier II
- Волны 10+: 20% шанс Tier III
- Волны 15+: 5% шанс Tier IV

Цена: `base_cost × TIER_COST_MULT[tier-1]`. Купленный оффер удаляется из пула.

---

## 💪 Магазин — Прокачка тела

9 статов. Цена растёт: `cost_at_level = base_cost + level × (base_cost / 3)`.

| Стат | Эффект за уровень | Base | Max |
|------|-------------------|------|-----|
| ❤️ max_hp | +20 макс HP | 20 | 10 |
| 🛡️ armor | +2 брони | 25 | 10 |
| 👟 speed | +20 скорости | 15 | 10 |
| ⚔️ damage | **+8% урон ко всем оружиям** | 20 | 15 |
| ⚡ attack_speed | **+10% скор. атаки** | 25 | 10 |
| 🎯 range | **+15% дальности** | 15 | 10 |
| 🔱 pierce | **+1 пробитие** (flat) | 30 | 5 |
| 🩸 lifesteal | +4% жизнекражи | 35 | 5 |
| 💨 dodge | +5% уклонения (макс 80%) | 30 | 4 |

> Статы оружия (damage/attack_speed/range/pierce) теперь — **процентные модификаторы**, применяемые ко всем weapons. Pierce — flat-добавка.

---

## 🎒 Магазин — Аксессуары

4 случайных предмета из пула, покупаются один раз за волну.

| Предмет | Редкость | Эффект | Цена |
|---------|----------|--------|------|
| 👢 Сапоги | 1 | +50 скорости | 30 |
| 🥊 Перчатки | 1 | +8% урон | 30 |
| 💊 Аптечка | 1 | +40 макс HP, +40 HP | 35 |
| 🧛 Вампир | 2 | +8% жизнекражи | 45 |
| 🛡️ Щит | 2 | +5 брони | 40 |
| 💍 Кольцо силы | 2 | +12% урон, +10 макс HP | 50 |
| 📿 Амулет | 2 | +10% скор. атаки, +30 скорости | 50 |
| 🔭 Прицел | 2 | +25% дальности, +1 пробитие | 55 |
| 🍀 Клевер | 3 | +10% уклонения | 55 |
| 👑 Корона | 3 | +20% урон, +5 брони | 70 |

---

## 📊 HUD

Top-bar:
- ❤️ HPBar + текст HP / max_hp
- ⚡ XPBar + Lv N
- 💜 Материалы
- 🌊 Волна N / 20
- ⏱ Таймер волны

---

## 🖥 Экраны состояний

- **Title**: «🥔 BROTATO MINI» + кнопка «Начать игру»
- **Pause**: «⏸ ПАУЗА» + кнопка «Продолжить» (триггер: Esc)
- **GameOver**: «💀 GAME OVER» + статистика + «Снова»
- **Win**: «🏆 ПОБЕДА!» + статистика + «Снова»
- **Shop**: 3 вкладки (Оружие/Прокачка тела/Аксессуары) + «Следующая волна»

---

## 🎨 Polish: пауза, shake, частицы, звук

### Пауза
- Esc → `get_tree().paused = true/false`
- `PauseScreen` имеет `process_mode = ALWAYS` (UI работает на паузе)
- `GameManager`, `AudioBus` — также `ALWAYS`

### Screen shake
- Глобальный сигнал `GameManager.request_shake(amount)`
- `Main._on_request_shake` копит максимум, `_update_shake` уменьшает с `SHAKE_DECAY = 12`
- Сдвигает `Camera2D.offset` случайным вектором × amount

Триггеры:
| Событие | Shake |
|---------|-------|
| Pistol shot | 1.5 |
| Sniper shot | 4.0 |
| Shotgun shot | 5.0 |
| SMG shot | 0.6 |
| Player урон | 3.0 |
| Enemy death | 1.0 |
| Boss death | 10.0 |

### Частицы (`HitParticle`)
6 ColorRect-узлов разлетаются по случайным векторам, alpha затухает за 0.4с. Спаунятся при:
- Попадании пули по врагу (жёлтые)
- Смерти врага (цвет врага, через `set_color`)

### Звук (`AudioBus` autoload)
- Пул из 10 `AudioStreamPlayer`, round-robin
- Звуки генерируются процедурно из `PackedByteArray` (sin-волна или белый шум, 22050 Hz, 16-bit)
- Идентификаторы: `pistol_fire`, `shotgun_fire`, `sniper_fire`, `smg_fire`, `flamer_fire`, `minigun_fire`, `enemy_hit`, `enemy_die`, `player_hurt`, `boss_die`, `level_up`, `combine`, `buy`

---

## 🏗 Архитектура скриптов

### GameManager.gd (Autoload)
- `player_stats`, `body_upgrades`, `owned_items`, `player_weapons`
- `WEAPON_DEFS`, `BODY_UPGRADES`, `SHOP_ITEMS` (только аксессуары)
- Сигналы: `wave_changed`, `player_died`, `game_won`, `boss_killed`, `request_shake`
- **Weapon API**: `add_weapon`, `remove_weapon`, `combine_weapons`, `can_combine`, `get_weapon_def`, `get_weapon_effective_stats`, `get_weapon_sell_price`, `get_weapon_buy_price`, `roll_shop_weapons`

### AudioBus.gd (Autoload)
- `_streams: Dictionary[String, AudioStreamWAV]` — все звуки в памяти
- `play(id)` — round-robin воспроизведение
- `_make_tone`, `_make_noise` — генерация

### Main.gd
- Состояния, переключение экранов, кнопок
- Pause toggle через `_unhandled_input` (Esc)
- Screen shake — `_on_request_shake` + `_update_shake` в `_process`
- При старте волны: cleanup групп `enemies/bosses/drops/enemy_bullets`

### Player.gd
- `weapon_cooldowns: Array[float]` — per-weapon
- `_handle_shooting` — цикл по слотам
- `_fire_weapon` — единая точка, обрабатывает `bullet_count + spread_deg` + звук + shake
- `_spawn_bullet` → `Bullet.setup_extended`

### Bullet.gd
- `setup_extended(p)` принимает `dir/damage/pierce/speed/lifetime/pattern/color`
- Визуально адаптируется под `pattern` (sniper — длинный, smg — мелкий)
- При попадании: партикл + звук `enemy_hit`

### Enemy.gd
- `setup(...)` и `setup_boss(..., ability)` — двухрежимная инициализация
- `_boss_ai(delta)` → `_boss_dash / _boss_shoot / _boss_summon`
- При смерти: партикл цвета врага, звук `enemy_die / boss_die`, shake

### EnemyBullet.gd
- Снаряд босса, Node2D
- При сближении с игроком < 24px — `take_damage` + `queue_free`

### WaveManager.gd
- `BOSS_WAVES = [5, 10, 15, 20]` и `BOSS_DEFS`
- `_try_spawn_boss()` — увеличенный SpawnIndicator + setup_boss
- `_on_boss_killed`: волна 20 → win, иначе → магазин
- `SpawnIndicator` (inner class) с `set_big()` для боссов

### Shop.gd
- Три вкладки: weapon (стартовая) / body / item
- `_build_slots_grid` / `_build_shop_weapons_grid` — карточки с цветом тира, эффективными статами, кнопками
- Combine, sell, buy с обновлением UI и звуком
- Исправленный `_refresh_body_btns` (один цикл по индексу)

### HitParticle.gd
- 6 ColorRect разлетаются по случайным направлениям, alpha затухает
- `set_color(c)` — окрашивает все частицы

---

*Документ актуален для коммита на момент написания.*
