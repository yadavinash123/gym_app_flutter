# Phase 3: offline exercise library

**Historical record:** the later [3D upgrade](3d-upgrade.md) replaces the three line-skeleton sketches with one actual animated push-up GLB and expands the catalog to 22 guides.

## Delivered

Workouts → Browse exercises opens a local catalog of **21 guides**. Search matches
names, movement, muscles and equipment. Muscle, equipment, experience and favorites
filters combine. Front/back muscle regions share geometry with hit testing; labeled
chips provide an alternative to touching small regions. The diagram is simplified,
not a precise anatomical or recovery visualization.

Each guide has primary/secondary muscle groups, equipment, experience, movement
category, written steps, posture cue, common mistake, general breathing/comfort
advice and a selectable/copyable source URL. Related guides link to real catalog IDs.
Source pages require a browser/network; bundled guides and playback work offline.
No external media or new packages were added.

Favorites live in `<application-support>/fitforge/exercise_preferences.json`:

```json
{"version": 1, "favorites": ["squat", "wall-pushup"]}
```

The repository serializes the full read/modify/write operation. Failed writes keep
previous UI state and expose a retryable message. Invalid schema is preserved and
surfaced instead of silently replacing preferences. JsonStore backup behavior applies.
The catalog and motions are immutable versioned JSON in `assets/exercises/`.

## Animation scope and provenance

Three original, bundled, articulated 2D movement sketches: bodyweight squat,
dumbbell curl and wall push-up. JSON keyframes drive joint-angle interpolation;
limb lengths remain constant. The wall push-up uses two-link inverse kinematics.
Flutter CustomPainter draws the skeleton; AnimationController drives playback.
These are moving skeletal diagrams, not still image effects or downloaded media.

The reusable ExerciseAnimationPlayer supports play/pause, replay, 0.5×/1×/1.5× speed,
loop, frame stepping, scrubbing and a larger view. Supported view is explicitly
**fixed side view**. Only curl has a separate common-mistake sequence (upper-arm
swing and torso rocking). Playback starts paused, stops when backgrounded or when
TickerMode disables the route, and does not automatically resume. System reduced
motion disables playback while retaining frame stepping and scrubbing.

All three sketches and their renderer were created for this project. No third-party
images, videos, models or animation licenses are required. Written guidance is
briefly paraphrased from the references below; no reference site's media is bundled.
There has been **no independent trainer or clinical review** of these sketches or
adaptations. The UI states this. They are educational illustrations, not a form
assessment or a validated training prescription.

## Written references

Each catalog entry includes its exact source URL. Sources consulted:

- Mayo Clinic individual exercise videos: squat, dumbbell/barbell biceps curl,
  bent-over row, chest press, triceps extension, modified push-up and lunge.
- [Mayo Clinic Health System: quick workouts](https://www.mayoclinichealthsystem.org/hometown-health/speaking-of-health/can-quick-workout-boost-health-and-fitness): shoulder press, bridge and step-up.
- [NHS strength exercises](https://www.nhs.uk/live-well/exercise/strength-exercises/): wall push-up, calf raise and sit-to-stand.
- [NHS sitting exercises](https://www.nhs.uk/live-well/exercise/sitting-exercises/): trunk rotation, ankle mobility and chest stretch.
- [NHS walking for health](https://www.nhs.uk/live-well/exercise/walking-for-health/).
- [NASM bird dog](https://www.nasm.org/resource-center/exercise-library/bird-dog) and [dead bug](https://www.nasm.org/resource-center/exercise-library/dead-bug).
- [ACE front plank](https://www.acefitness.org/resources/everyone/exercise-library/32/front-plank/).
- [Mayo Clinic strength training](https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/strength-training/art-20046031): general breathing guidance.

Muscle labels, experience tags and related-guide relationships are editorial catalog
metadata, not personalized suitability decisions. A related guide is not an injury
substitution. Experience tags are not a clearance to exercise.

## Remaining scope

This is a functional **starter** for Phase 3, not the entire master-brief catalog.
Still outstanding: independent professional review, the remaining exercises, more
reviewed animations, multiple character appearances and additional genuine views.
Goal-specific sets/reps/rest, easier/harder prescriptions, workout history and
recovery indicators belong to subsequent programming/logging work and are not
invented here. No exercise is automatically added to a user's weekly outline.

APK web execution is not supported. This project still uses phone filesystem APIs;
web requires a separate platform storage adapter and Flutter web build.

## Verification

Automated coverage checks catalog references and asset consistency; limb length
and coordinate bounds throughout every motion; combined filters; concurrent favorite
updates across reload; corrupt schema preservation; save failure UI; playback,
stepping and reduced motion; muscle hit regions; missing-ID recovery; and phone
layout at 200% text size. The existing profile/planning tests remain in the suite.
Physical-device behavior and iOS compilation still require validation.

Validation results: all 29 automated tests passed. Phone-size library and curl-guide
screens were rendered and visually inspected at 390×844. This is headless layout
verification, not installation or sensor testing on a physical device.

`flutter analyze --no-pub`: no issues found.
`flutter build apk --debug --no-pub`: succeeded. Both exercise JSON assets were verified inside the generated APK.
