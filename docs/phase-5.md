# Phase 5: Offline Food Catalog, Nutrition Calculations, and Meal Logs

## Overview

Phase 5 implements the complete offline nutrition and meal logging system for FitForge AI.
Users can view daily calorie and macronutrient targets derived transparently from their physical metrics and training goals, browse and search an offline verified food catalog with realistic portions, create and save custom food items, log meals (Breakfast, Lunch, Dinner, Snacks) and hydration, and persist all records locally on their device with automatic backup recovery.

All existing Phase 1, Phase 2, Phase 3, and Phase 4 features and tests remain preserved and 100% passing.

---

## Architecture & Components

### 1. Offline Food Catalog (`assets/nutrition/food_catalog.json` & `lib/features/nutrition/models/food_item.dart`)
- **Verified Offline Catalog**:
  - 52 diverse, evidence-based food items covering Indian culinary staples (Roti, Basmati/Brown Rice, Moong/Toor Dal, Chana, Rajma, Soy Chunks, Paneer, Low-Fat Paneer, Dahi/Curd, Cow Milk, Besan Chilla, Roasted Makhana/Chana, Desi Ghee) and global fitness foods (Chicken Breast, Chicken Thigh, Eggs, Egg Whites, Salmon, Tilapia, Whey Protein, Plant Protein, Rolled Oats, Tofu, Soy/Almond Milk, Greek Yogurt, Peanut Butter, Almonds, Walnuts, Chia Seeds, Olive Oil, Fruits, Vegetables).
  - Exact nutritional values based on official composition databases: **ICMR-NIN Indian Food Composition Tables (IFCT 2017)** and **USDA FoodData Central**.
  - Verified source references and URLs embedded in every record.
- **Portion System**:
  - Each item includes practical, recognizable portion measures with exact gram equivalents: e.g. "1 medium roti (35g)", "1 medium bowl / katori (150g)", "1 cup (200ml)", "1 large egg (50g)", "1 scoop (30g)".
  - Automatic proportional scaling of calories and macronutrients for any portion quantity.
- **Validation & Search**:
  - Constructor validates kebab-case slug regex (`^[a-z][a-z0-9-]*$`), non-empty name and portions, positive serving sizes, and non-negative macros.
  - Case-insensitive search across name, category, and diet.
  - Multi-dimensional filtering by Category, Diet (Vegetarian, Vegan, Non-vegetarian), and High-Protein ($\ge 10\text{g} / 100\text{g}$).
- **Custom Foods (`custom_foods.json`)**:
  - Users can create custom food items with custom portion units and brand notes.
  - Stored locally via `JsonStore` and unified with the base catalog.

### 2. Validated Nutrition Calculations (`lib/features/nutrition/models/nutrition_targets.dart`)
- **Resting Energy (BMR)**:
  - Simplified Mifflin–St Jeor equation: $10 \times \text{weight (kg)} + 6.25 \times \text{height (cm)} - 5 \times \text{age} \pm \text{sex coefficient}$ (+5 for Male, -161 for Female).
  - TDEE = $\text{BMR} \times \text{activityFactor}$ (1.2–1.9; default 1.4).
- **Goal Adjustments**:
  - `Build muscle` / `Build strength`: Conservative surplus of $+250\text{ kcal/day}$ for lean mass gain without excessive fat accumulation.
  - `Fat loss`: Conservative deficit of $-400\text{ kcal/day}$ for sustainable fat loss.
  - `Weight maintenance` / other goals: Maintenance calories ($+0\text{ kcal}$).
- **Evidence-Based Macronutrient Breakdown**:
  - **Protein**: Jäger et al., 2017 (ISSN Position Stand). 1.6–2.0 g/kg bodyweight (higher in fat loss deficits to protect lean muscle mass). Overridden if user entered a custom protein target.
  - **Fat**: 25% of total caloric intake (healthy essential fats).
  - **Carbohydrates**: Remaining calories divided by $4\text{ kcal/g}$.
  - **Fiber**: $14\text{g} \text{ per } 1,000\text{ kcal}$ ($\sim 25\text{--}35\text{g/day}$).
  - **Hydration Target**: European Food Safety Authority (EFSA) guideline of $35\text{ ml per kg of bodyweight}$ (clamped to 2,000–4,000 ml).
- **Safety Disclaimers & Suppression**:
  - If user is under 18 years of age or selected `clinicalNutrition = true`, automated energy and macro estimation is withheld and labeled with clinical safety notices. User personal targets remain available.

### 3. Meal Logging & Atomic Persistence (`lib/features/nutrition/data/nutrition_repository.dart`)
- **Data Models (`lib/features/nutrition/models/meal_log.dart`)**:
  - `LoggedFoodItem`: atomic record of logged item, portion name, total grams, multiplier, computed calories, protein, carbs, fat, fiber, and timestamp.
  - `Meal`: type (Breakfast, Lunch, Dinner, Snacks), items list, and calculated macro totals.
  - `DailyNutritionLog`: date (`YYYY-MM-DD`), 4 meals, water intake (ml), water target, and daily aggregates.
- **Atomic Local Persistence**:
  - Stored in `<application-support>/fitforge/nutrition_logs.json` and `<application-support>/fitforge/custom_foods.json`.
  - Serialized write queue via `_tail` in `JsonStore`, ensuring zero file corruption, atomic temporary write + rename, and automatic `.bak` recovery.
- **Riverpod Providers**:
  - `nutritionRepositoryProvider`, `foodCatalogRepositoryProvider`
  - `nutritionTargetsProvider`: reactive derivation from profile.
  - `nutritionLogsProvider`: reactive state notifier for all logs.
  - `dailyNutritionLogProvider(date)`: family provider returning current daily log or default empty log.
  - `todayNutritionLogProvider`: watches today's log.

### 4. Interactive User Interface (`lib/features/nutrition/screens/`, `widgets/`)
- **`NutritionScreen`**:
  - Top interactive day navigation bar (`<` previous day, `>` next day, calendar date picker).
  - Hero Target & Progress Card:
    - Calories consumed vs target with remaining kcal badge.
    - Color-coded `MacroProgressBar` indicators: Protein (`#B6FF3B`), Carbs (`#00D4FF`), Fat (`#FFB800`), Fiber (`#A78BFA`).
    - Info icon opening `NutritionReferenceDialog` with detailed Mifflin–St Jeor explanations and scientific citations.
  - Hydration tracker with visual progress bar and quick-log chips (`+250 ml`, `+500 ml`, reset).
  - Meal sections: Breakfast, Lunch, Dinner, Snacks with logged items, portion details, macros, delete actions, and "+ Add Food" buttons.
  - Day actions popup menu: "Copy yesterday's meals" and "Clear all meals".
  - Floating Action Button to quickly search and log food.
- **`FoodSearchScreen`**:
  - Real-time offline search with clear action.
  - Category and diet filter chips.
  - Food list tiles with macro badge and serving details.
  - Bottom sheet portion logger with target meal selection, portion measure picker, quantity counter, and dynamic macro calculation preview.
- **`CustomFoodScreen`**:
  - Form to enter custom food name, category, diet, serving size, macros, and source/brand.
  - Full input validation and instant availability in search.
- **`DashboardScreen` Integration**:
  - Displays daily nutrition targets summary and includes a direct "Open Daily Nutrition Log" action button.

---

## Verification & Test Results

1. **Static Analysis**:
   ```sh
   flutter analyze --no-pub
   ```
   Result: **No issues found!** (0 errors, 0 warnings, 0 hints).

2. **Automated Test Suite**:
   ```sh
   flutter test --no-pub
   ```
   Result: **All 61 tests passed!**
   - 45 original regression tests (onboarding, storage migrations, exercise catalog, 3D viewer, planning, settings, workout engine, session persistence).
   - 16 new Phase 5 unit, repository, and widget tests (`test/nutrition_test.dart`):
     - Food item schema validation and regex ID constraints.
     - Linear portion gram scaling and macro computations.
     - Multi-attribute search matching (query, category, diet, high-protein).
     - Mifflin–St Jeor BMR, TDEE, and goal deficit/surplus adjustments.
     - User personal calorie and protein overrides.
     - Clinical nutrition and minor suppression safeguards.
     - Logged food item and daily nutrition log JSON round-trip serialization.
     - Atomic meal addition, removal, and hydration tracking via `JsonStore`.
     - Cross-day meal copying and day clearing.
     - Automatic `.bak` corruption recovery.
     - Custom food creation, persistence, and deletion.
     - Macro progress bar rendering without flex overflows.
     - Nutrition calculation reference dialog with scientific citations.
