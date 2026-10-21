# 3D trainer upgrade

## Diagnosis and reference direction

The previous `ExerciseAnimationPlayer` painted line segments, circles and simple
weights with CustomPainter. Three scalar keyframe sequences moved a single side-view
skeleton. It had no human surface mesh, skinning, materials, lighting, depth or real
camera. The overlap between the torso and upper arm further reduced readability.
It could not produce the supplied reference's human trainer through styling alone.

Forma (https://workout.codingmarble.com/) and MuscleWiki (https://musclewiki.com/)
were inspected for their exercise-first presentation and muscle-based navigation.
No proprietary code, characters, motion, or imagery was copied. The attached image
informed the dark teal stage, prominent model, compact controls and muscle labels.

## Implemented in the existing app

- Removed the line-skeleton player and its three JSON motion sketches.
- Added one real animated human **push-up** GLB, first in the existing catalog.
- Added a 3D asset repository and versioned manifest independent of exercise metadata.
- Integrated Exercise3DViewer with the existing exercise detail screen and favorites.
- Bundled Three.js, HTML, GLB and license notices. No CDN, server, database or runtime
  download is needed. Phone JSON persistence and profile schema are unchanged.
- Viewer: play/pause, replay, looping, 0.5×/1×/1.5× speed, time slider, orbit gestures,
  zoom, front/side/back presets, fullscreen and phase labels.
- Optional upstream muscle surface emphasis; explicitly approximate, not a measured
  activation signal or an anatomically segmented 3D selection map.
- Loading timeout, retry, unsupported-device fallback, missing-clip rejection,
  app/background pause, route visibility pause, reduced-motion frame inspection and
  disposal. Native full-screen route restores the selected time, paused.
- The other 21 guides show an honest muscle illustration and written guidance.

## Rendering choice

Evaluated `model_viewer_plus` 1.10.0: Apache-2.0, Android/iOS/web, glTF support through
Google's model-viewer WebView component. Its stock wrapper is convenient for simple
model presentation, but custom exercise state and mesh control still require JS.
Chosen: official `webview_flutter` 4.14.1 (BSD-3-Clause) with a pinned Three.js 0.186.1
(MIT) renderer. This directly samples every configured animation clip at the same
playhead, supports model-specific camera framing and can later support accurate
mesh picking once segmented assets exist. The WebView package supports Android
SDK 24+ and iOS 13+; the project already targets Android 24+ / iOS 15+.

The HTML loads a locally bundled classic JS script. GLB bytes arrive from rootBundle
in bounded platform-channel messages. CSP blocks network connections, and external
navigation is rejected. No global cleartext traffic exemption was added.
The repository rejects a static, mismatched, truncated or externally dependent GLB.
WebGL must be supported by the installed system WebView; errors remain recoverable.

## Asset provenance and repair

See `assets/trainer/ATTRIBUTION.txt`, bundled licenses, `manifest.json` hashes and
`docs/3d/upstream-push-up-metadata.json`. The source is OpenGym3D's CC0 push-up export:
MakeHuman/MPFB human mesh and rig with the Mesh2Motion Pushup clip. The upstream
pipeline is MIT. Other files in that library, including squat/curl, are marked with
separate Mixamo redistribution restrictions and were not copied.

The first glTF Validator run found an empty morph-weight track targeting a mesh
without morph targets. `tools/trainer/prepare_asset.py` removes that invalid track
and updates the manifest hash. The skeletal animation is untouched. The corrected
GLB has zero validator errors and one warning about a non-root skinned mesh. That
warning is retained; visual and transform tests cover the exported hierarchy.

The preview has 163 bones and a 1.533-second clip. It is a semi-realistic anatomical
male, with original runtime vertex colors suggesting shorts and footwear. It has
no skin texture, hair, separate clothing mesh, or female counterpart. It does not
match the supplied image's final character-art quality yet. It is labeled a technical
preview; automated/visual QA is not a qualified exercise technique review.

New push-up instructions are concise adaptations of:
https://www.nasm.org/resource-center/exercise-library/push-up
No source imagery was copied. Related wall/knee guides remain available. No model
is labeled “correct form” without review and no incorrect-form clip is fabricated.

## Build and verification commands

```sh
cd tools/trainer
npm ci
npm run build
npm test
cd ../..
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

Node tools are development-only; their node_modules are ignored. The generated JS
is committed as an app asset, so Flutter builds do not need Node. `CHROME_BIN` can
select another local Chrome binary for the browser verification suite.

## Remaining work and asset acquisition plan

The screenshot's finished male/female trainer pair requires licensed or commissioned
character art: consistent shared rig, athletic garments and footwear, mobile LODs,
textures, and exercise-specific clips. Start with squat, shoulder press and push-up;
require neutral, front, side and rear inspections, contact checks, no mesh penetration,
and a qualified trainer's approval of each movement and each mistake example.
Ship only clips passing the same manifest/GLB/viewer checks used here.

Female character selection, remaining exercise animations, professionally reviewed
correct/mistake clips, a truly segmented/pickable 3D muscle map, audio coaching and
session sets/reps/weight/rest tracking are not implemented in this increment. The
existing weekly outline is preserved and links to the library; it has no session
engine to connect yet. Existing Nutrition/Progress/AI tabs remain their prior explicit
placeholders. No 60 FPS claim is made without device profiling.

## Validation results so far

- Flutter regression suite: **29 passed**.
- Flutter analyzer: **no issues**.
- Khronos glTF Validator: **0 errors, 1 warning** (documented above).
- Browser suite: passed real GLB loading, changed bone transforms when seeking,
  play/pause, camera views/zoom, surface emphasis, speed/nonloop ending, fullscreen
  bridge, reduced motion, background pause, wrong-clip rejection/retry, initial seek,
  disposal and **zero HTTP(S) requests**. Rendered phone-size frames inspected.
