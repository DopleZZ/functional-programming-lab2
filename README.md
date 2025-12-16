# Лабораторная работа №2

**Вариант:** avl-set (AVL-дерево, интерфейс Set)

**Язык:** Haskell

**Студент:** Пикулин Артём Алексеевич

**Группа:** P3332

---

## Цель

Освоиться с построением пользовательских типов данных, полиморфизмом, рекурсивными алгоритмами и средствами тестирования (unit testing, property-based testing).

---

## Требования

1. Функции: добавление и удаление элементов, фильтрация, отображение (map), свертки (левая и правая).
2. Структура должна быть моноидом.
3. Структуры данных должны быть неизменяемыми.
4. Библиотека должна быть протестирована в рамках unit testing.
5. Библиотека должна быть протестирована в рамках property-based тестирования (минимум 3 свойства, включая свойства моноида).
6. Структура должна быть полиморфной.

---

## Реализация

### Структура данных

Внутреннее представление — AVL-дерево с кэшированной высотой в каждом узле:

```haskell
data Tree a = Empty | Node !(Tree a) !a !(Tree a) !Int

newtype AVLSet a = AVLSet { unSet :: Tree a }
```

### API модуля Data.AVLSet

| Функция | Сигнатура | Описание |
|---------|-----------|----------|
| `empty` | `AVLSet a` | Пустое множество |
| `singleton` | `a -> AVLSet a` | Множество из одного элемента |
| `insert` | `Ord a => a -> AVLSet a -> AVLSet a` | Добавление элемента |
| `delete` | `Ord a => a -> AVLSet a -> AVLSet a` | Удаление элемента |
| `member` | `Ord a => a -> AVLSet a -> Bool` | Проверка принадлежности |
| `fromList` | `Ord a => [a] -> AVLSet a` | Построение из списка |
| `toList` | `AVLSet a -> [a]` | Преобразование в отсортированный список |
| `mapSet` | `Ord b => (a -> b) -> AVLSet a -> AVLSet b` | Отображение |
| `filterSet` | `Ord a => (a -> Bool) -> AVLSet a -> AVLSet a` | Фильтрация |
| `foldrSet` | `(a -> b -> b) -> b -> AVLSet a -> b` | Правая свертка |
| `foldlSet` | `(b -> a -> b) -> b -> AVLSet a -> b` | Левая свертка |
| `union` | `Ord a => AVLSet a -> AVLSet a -> AVLSet a` | Объединение множеств |
| `validAVL` | `AVLSet a -> Bool` | Проверка инварианта AVL |

### Реализованные инстансы

```haskell
instance Eq a => Eq (AVLSet a)
instance (Ord a) => Semigroup (AVLSet a)
instance (Ord a) => Monoid (AVLSet a)
instance Foldable AVLSet
instance Show a => Show (AVLSet a)
```

### Ключевые элементы реализации

**Балансировка (rebalance):**
- Вычисляет баланс-фактор узла (разница высот левого и правого поддеревьев).
- При баланс-факторе > 1 выполняет правый поворот (с предварительным левым поворотом левого ребенка при необходимости — случай LR).
- При баланс-факторе < -1 выполняет левый поворот (с предварительным правым поворотом правого ребенка при необходимости — случай RL).

**Вставка (insertTree):**
- Рекурсивный спуск по дереву с последующей балансировкой на обратном пути.

**Удаление (deleteTree):**
- Поиск удаляемого узла, замена минимальным элементом правого поддерева, балансировка.

**Сравнение (Eq):**
- Сравнение через упорядоченный обход (in-order), без дополнительной сортировки.

---

## Тестирование

### Unit-тесты

```haskell
describe "AVLSet basic unit tests" $ do
  it "insert then member" $ member 5 (insert 5 empty :: AVLSet Int) `shouldBe` True
  it "delete removes element" $ let s = delete 3 (insert 3 empty :: AVLSet Int) in member 3 s `shouldBe` False
```

### Property-based тесты

| Свойство | Описание |
|----------|----------|
| `prop_monoid_left_id` | Левая единица моноида: `mempty <> s == s` |
| `prop_monoid_right_id` | Правая единица моноида: `s <> mempty == s` |
| `prop_monoid_assoc` | Ассоциативность: `(a <> b) <> c == a <> (b <> c)` |
| `prop_valid_avl` | Инвариант AVL сохраняется после любых операций |
| `prop_map_comp` | Композиция map: `mapSet (f . g) == mapSet f . mapSet g` |
| `prop_union_member` | Принадлежность объединению: `member x (a <> b) == (member x a \|\| member x b)` |
| `prop_insert_member` | После вставки элемент присутствует |
| `prop_delete_member` | После удаления элемент отсутствует |
| `prop_filter_preserve` | Фильтрация сохраняет только элементы, удовлетворяющие предикату |

### Результаты тестирования

```
AVLSet basic unit tests
  insert then member [OK]
  delete removes element [OK]
AVLSet properties
  Monoid left identity [OK]
    +++ OK, passed 100 tests.
  Monoid right identity [OK]
    +++ OK, passed 100 tests.
  Monoid associativity [OK]
    +++ OK, passed 100 tests.
  AVL invariant holds [OK]
    +++ OK, passed 100 tests.
  Map composition [OK]
    +++ OK, passed 100 tests.
  Union membership [OK]
    +++ OK, passed 100 tests.
  Insert membership [OK]
    +++ OK, passed 100 tests.
  Delete membership after insert [OK]
    +++ OK, passed 100 tests.
  Filter preserves predicate [OK]
    +++ OK, passed 100 tests.

Finished in 0.0226 seconds
11 examples, 0 failures
```

---

## Сборка и запуск

```bash
cd lab2
stack build
stack test
stack run
```

---

## Выводы

1. Реализована полиморфная неизменяемая структура данных AVLSet на базе AVL-дерева.
2. Структура является моноидом с операцией объединения и пустым множеством в качестве нейтрального элемента.
3. Реализованы все требуемые операции: добавление, удаление, фильтрация, отображение, левая и правая свертки.
4. Сравнение множеств выполняется без сортировки за счет использования упорядоченного обхода дерева.
5. Тестирование покрывает как базовые сценарии (unit-тесты), так и алгебраические свойства структуры (property-based тесты).
6. Все три закона моноида проверены property-based тестами.
7. Инвариант AVL-дерева (баланс-фактор в пределах [-1, 1]) проверяется автоматически на случайных данных.
