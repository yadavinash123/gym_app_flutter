# Phase 2 — profile, preferences and initial planning

## Implemented behavior

The ten-step onboarding covers nickname/welcome, gender preference, experience,
optional age/height/weight/waist, primary and secondary goals, environment/equipment,
training frequency/duration/time/rest days, diet/allergies/restrictions/cuisine/INR budget,
optional movement limitations and personal nutrition guidance, then an editable plan.

Profile settings links directly to each section. The editor keeps changes in memory
until the final review is saved. Cancel leaves the saved document untouched. Failed
saves retain the editor values and offer retry. Required names, numeric ranges, finite
numbers, whole-number ages and schedule conflicts are validated.

The weekly outline uses the primary goal, experience and available days. Explicit rest
days are preserved. Beginner strength-focused outlines contain at most three strength
slots; additional slots are lighter activities. Users can edit focus labels and move
active days, provided the active-day count matches their availability. Reset rebuilds
the outline locally. Changing training preferences regenerates it for review; personal
nutrition targets remain intact. Secondary goals and equipment are stored preferences
for the future detailed workout engine, not claims of exercise-level personalization.

Movement restriction notes, avoided exercises, or the limitations switch withhold
strength/cardio suggestions. The displayed Mobility slots are explicitly labeled as
time to review suitable movement with a qualified professional, not exercise clearance.
This is a conservative product rule, not a validated clinical assessment.

Home shows today's planned focus and actual saved targets. Workouts shows the whole
week. Neither screen invents completed workouts, consumed food or sensor readings.

## Storage and migration

`profile.json` schemaVersion 2 adds identity, canonical metric measurements, unit
preference, equation preference, activity multiplier, secondary goal, equipment,
scheduling, dietary preferences, optional limitations, personal targets, and a seven-day
schedule. Profile plus schedule are stored in one document so they cannot become
partially updated across two files. The existing queued/backup JSON store is retained.

Version 1 profiles migrate in memory with absent measurements and no inferred sex
coefficient. Reading a v1 profile does not rewrite it. An explicit successful save writes
v2. Unknown schemas and malformed records are rejected without deleting them.

Canonical height/waist use cm; weight uses kg. Imperial entry converts inches using
2.54 cm/in and pounds using 0.45359237 kg/lb. Input conversion displays two decimal
places. Save/reopen may round canonical measurements to that displayed precision.
Numeric validation limits are data-entry bounds, not medical recommendations.

## Calculation assumptions

- Resting energy: simplified Mifflin–St Jeor, `10 × kg + 6.25 × cm − 5 × age`,
  plus 5 or minus 161 according to the explicitly selected coefficient. No coefficient
  is inferred from gender identity. Missing inputs or Skip estimate yield no energy value.
- Maintenance: resting estimate × a user-editable activity multiplier (1.2–1.9;
  default 1.4). This multiplier is a rough product assumption, not measured activity.
- No deficit or surplus is applied automatically for a body-composition goal.
- Protein: general healthy exercising-adult range of 1.4–2.0 g/kg/day. No single target
  is automatically selected. A personal target overrides the displayed range.
- Optional BMI: kg / height in metres squared, shown without diagnostic classification.
- Unknown age, under-18 age, or selected personal nutrition guidance disables automatic
  nutrition estimates. Personal targets can still be recorded and are identified as user
  entries. Estimates are not suitable for every adult or clinical circumstance.

Primary references, also identified in the app's calculation-reference panel:

- [Mifflin et al., 1990](https://pubmed.ncbi.nlm.nih.gov/2305711/),
  DOI 10.1093/ajcn/51.2.241. Original study: healthy adults aged 19–78; the simplified
  sex-specific equations are reported in the abstract.
- [Jäger et al., ISSN position stand, 2017](https://link.springer.com/article/10.1186/s12970-017-0177-8),
  DOI 10.1186/s12970-017-0177-8. General protein ranges for exercising individuals.

## Boundaries

This phase supplies an initial weekly structure and nutrition estimates. It does not
provide reviewed exercise prescriptions, animation assets, workout sessions, meal plans,
food logging, AI access, or health sensor integrations. Those remain later phases.
Portable backup/export and application-level encryption are still pending. No database
engine, backend, or new runtime dependency has been added. Web support remains absent;
this build uses the Android/iOS private filesystem.

## Verification

- 20 permanent tests cover v1 migration without rewriting on read, expanded-profile
  persistence, interrupted/corrupt-file recovery, all valid weekly rest-day combinations,
  numerical reference cases, suppressed estimates, custom targets, invalid inputs,
  ten-step onboarding, save failure/retry, cancellation, settings navigation, unit
  conversion and 200% text scaling at a 390 × 844 logical phone size.
- Headless phone-sized views were rendered and inspected for layout. This does not
  replace testing with real system fonts, keyboards, screen readers and a physical phone.
- No new dependency or database engine was introduced.
- Final `flutter analyze --no-pub`: passed with no issues.
- All 16 repository/planning tests and all 4 phone UI tests passed; the latter were
  rerun after adding the explicit return-to-home action in settings.
- Final `flutter build apk --debug --no-pub`: passed. Updated APK:
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Physical-device testing and iOS compilation remain pending.
