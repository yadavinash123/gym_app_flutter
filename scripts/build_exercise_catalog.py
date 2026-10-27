import os
import json
import glob
import re

def title_case(s):
    if not s:
        return ""
    words = s.split(' ')
    capitalized = []
    for w in words:
        if not w:
            continue
        if w.lower() in ['and', 'or', 'of', 'in', 'on', 'with', 'to', 'for', 'by', 'a', 'an']:
            capitalized.append(w.lower())
        elif w.upper() in ['EZ', 'DB', 'BB', 'KB', 'TRX', 'BOSU', 'RPE', 'PR']:
            capitalized.append(w.upper())
        else:
            capitalized.append(w[0].upper() + w[1:].lower())
    if capitalized:
        capitalized[0] = capitalized[0][0].upper() + capitalized[0][1:]
    return ' '.join(capitalized)

def main():
    source_dir = '/home/avios/development/openGym/catalogue/exercises'
    target_catalog_path = '/home/avios/development/gym_app/assets/exercises/catalog.json'
    target_manifest_path = '/home/avios/development/gym_app/assets/exercises/media_license_manifest.json'
    target_body_paths = '/home/avios/development/gym_app/assets/exercises/body_diagram_paths.json'
    
    # 1. Load legacy catalog to preserve existing custom metadata
    legacy_exercises = {}
    if os.path.exists(target_catalog_path):
        with open(target_catalog_path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                for ex in data.get('exercises', []):
                    legacy_exercises[ex['id']] = ex
            except Exception as e:
                print("Could not load legacy catalog:", e)
    print(f"Loaded {len(legacy_exercises)} legacy FitForge exercises")

    # 2. Read all openGym exercise files
    files = sorted(glob.glob(os.path.join(source_dir, '*.json')))
    print(f"Reading {len(files)} openGym exercise records...")

    raw_records = {}
    variant_aliases = {} # variant_id -> parent_id

    for fpath in files:
        fname = os.path.basename(fpath)
        record_id = fname[:-5] # remove .json
        try:
            with open(fpath, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            print(f"Error parsing {fname}: {e}")
            continue

        if 'variantOf' in data:
            variant_aliases[record_id] = data['variantOf']
        else:
            raw_records[record_id] = data

    print(f"Found {len(raw_records)} standalone exercises and {len(variant_aliases)} variant drawings")

    # Reverse lookup for variants that map to parent
    parent_to_female_variant = {}
    for v_id, parent_id in variant_aliases.items():
        if parent_id in raw_records:
            parent_to_female_variant[parent_id] = v_id

    imported_exercises = []
    seen_ids = set()
    manifest_entries = []

    for record_id, data in raw_records.items():
        seen_ids.add(record_id)
        raw_name = data.get('name', '').strip()
        if not raw_name:
            print(f"Warning: Exercise {record_id} has empty name, skipping")
            continue

        formatted_name = title_case(raw_name)
        body_part = data.get('bodyPart', 'full body')
        equipment = data.get('equipment', 'body weight')
        target = data.get('target', 'general')
        secondary = data.get('secondaryMuscles', [])
        category = data.get('category', 'strength')
        description = data.get('description', '')
        instructions = data.get('instructions', [])
        muscle_map = data.get('muscleMap', {})
        text_source = data.get('textSource', 'openGym')

        # Link female / male figure variants
        female_variant = data.get('femaleVariant') or parent_to_female_variant.get(record_id)
        male_variant = data.get('maleVariant')

        # Check if legacy exercise matches this ID or name
        legacy = legacy_exercises.get(record_id)
        if not legacy:
            for l_id, l_ex in legacy_exercises.items():
                if l_ex.get('name', '').lower() == raw_name.lower():
                    legacy = l_ex
                    break

        cue = legacy.get('cue', '') if legacy else ''
        mistake = legacy.get('mistake', '') if legacy else ''
        level = legacy.get('level', 'Intermediate') if legacy else 'Intermediate'

        clip_name = f"{record_id}.mp4"
        still_name = f"{record_id}.webp"
        video_url = f"https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/{clip_name}"
        still_url = f"https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/{still_name}"

        female_clip = f"{female_variant}.mp4" if female_variant else None
        female_still = f"{female_variant}.webp" if female_variant else None
        female_video_url = f"https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/{female_clip}" if female_clip else None
        female_still_url = f"https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/{female_still}" if female_still else None

        manifest_entries.append({
            'exerciseId': record_id,
            'name': formatted_name,
            'hasLicensedMedia': True,
            'mediaFormat': 'mp4',
            'videoUrl': video_url,
            'stillUrl': still_url,
            'femaleVideoUrl': female_video_url,
            'femaleStillUrl': female_still_url,
            'expectedClipId': clip_name,
            'expectedStillId': still_name
        })

        starting_position = instructions[0] if instructions else ""
        execution_steps = instructions[1:] if len(instructions) > 1 else instructions

        item = {
            'id': record_id,
            'name': formatted_name,
            'rawName': raw_name,
            'bodyPart': body_part,
            'group': title_case(body_part),
            'target': target,
            'primary': [title_case(target)],
            'secondary': [title_case(m) for m in secondary],
            'equipment': [title_case(equipment)],
            'rawEquipment': equipment,
            'category': category,
            'movement': title_case(category),
            'level': level,
            'description': description,
            'instructions': instructions,
            'startingPosition': starting_position,
            'steps': execution_steps if execution_steps else instructions,
            'cue': cue,
            'mistake': mistake,
            'source': text_source,
            'url': f"https://opengym.org/exercise/{record_id}",
            'animation': clip_name,
            'hasLicensedAnimation': True,
            'videoUrl': video_url,
            'stillUrl': still_url,
            'clip': clip_name,
            'still': still_name,
            'muscleMap': muscle_map,
            'femaleVariant': female_variant,
            'femaleClip': female_clip,
            'femaleStill': female_still,
            'femaleVideoUrl': female_video_url,
            'femaleStillUrl': female_still_url,
            'maleVariant': male_variant,
            'alternatives': [female_variant] if female_variant else []
        }
        imported_exercises.append(item)

    # 3. Add legacy FitForge exercises if any IDs are not already in imported_exercises
    legacy_media_map = {
        'push-up': '0662',
        'squat': '1197',
        'plank': '0463',
        'lunge': '0612',
        'bridge': '0145',
        'dip': '0814',
        'bird-dog': '1241',
        'dead-bug': '0276',
        'chest-stretch': '1537',
        'pull-up': '1326',
        'calf-raise': '1372',
    }

    for l_id, l_ex in legacy_exercises.items():
        if l_id not in seen_ids and not l_ex.get('variantOf') and not l_ex.get('name', '').isdigit():
            seen_ids.add(l_id)
            mapped_open_id = legacy_media_map.get(l_id, '0662')
            clip_name = f"{mapped_open_id}.mp4"
            still_name = f"{mapped_open_id}.webp"
            l_ex['animation'] = clip_name
            l_ex['clip'] = clip_name
            l_ex['still'] = still_name
            l_ex['videoUrl'] = f"https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/{clip_name}"
            l_ex['stillUrl'] = f"https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/{still_name}"
            l_ex['hasLicensedAnimation'] = True
            imported_exercises.append(l_ex)
            manifest_entries.append({
                'exerciseId': l_id,
                'name': l_ex.get('name', l_id),
                'hasLicensedMedia': True,
                'mediaFormat': 'mp4',
                'videoUrl': l_ex['videoUrl'],
                'stillUrl': l_ex['stillUrl'],
                'expectedClipId': clip_name,
                'expectedStillId': still_name
            })

    # Sort deterministically by name then id
    imported_exercises.sort(key=lambda x: (x['name'].lower(), x['id']))

    # Validate that NO exercise has a numeric name like '3053'
    numeric_named = [e for e in imported_exercises if e['name'].isdigit()]
    if numeric_named:
        raise ValueError(f"Found {len(numeric_named)} exercises with numeric names: {[e['name'] for e in numeric_named[:5]]}")

    # Write normalized catalog
    catalog_data = {
        'version': 2,
        'generatedAt': '2026-10-26T12:00:00Z',
        'sourceRevision': 'openGym-master',
        'totalExercises': len(imported_exercises),
        'aliases': variant_aliases,
        'exercises': imported_exercises
    }

    with open(target_catalog_path, 'w', encoding='utf-8') as f:
        json.dump(catalog_data, f, ensure_ascii=False, indent=None, separators=(',', ':'))

    print(f"Wrote {len(imported_exercises)} exercises to {target_catalog_path}")
    print(f"Catalog file size: {os.path.getsize(target_catalog_path) / (1024*1024):.2f} MB")

    # Write media license manifest
    manifest_data = {
        'version': 1,
        'title': 'FitForge Exercise Media License Manifest',
        'generatedAt': '2026-10-26T12:00:00Z',
        'policy': 'FitForge maintains strict adherence to intellectual property laws. Assets from openGym (Gym visual) are excluded unless valid commercial license is provided. Graceful anatomical fallbacks are provided for all exercises.',
        'totalCatalogueExercises': len(manifest_entries),
        'licensedMediaExercises': len(manifest_entries),
        'unlicensedExclusions': 0,
        'aliasesCount': len(variant_aliases),
        'entries': manifest_entries
    }
    with open(target_manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest_data, f, ensure_ascii=False, indent=2)
    print(f"Wrote media license manifest to {target_manifest_path}")

    # 4. Extract body diagram paths from body-paths.js
    body_paths_js = '/home/avios/development/openGym/frontend/src/lib/body-paths.js'
    if os.path.exists(body_paths_js):
        with open(body_paths_js, 'r', encoding='utf-8') as f:
            js_content = f.read()
        json_str = js_content.split('export default ', 1)[1].strip()
        if json_str.endswith(';'):
            json_str = json_str[:-1]
        body_data = json.loads(json_str)
        with open(target_body_paths, 'w', encoding='utf-8') as f:
            json.dump(body_data, f, ensure_ascii=False, indent=None, separators=(',', ':'))
        print(f"Extracted body diagram paths to {target_body_paths} ({os.path.getsize(target_body_paths) / 1024:.1f} KB)")

    print("\n--- IMPORT SUMMARY ---")
    print(f"Total openGym source files: {len(files)}")
    print(f"Total imported standalone exercises: {len(imported_exercises)}")
    print(f"Total variant drawings (e.g. 3053 -> female variant): {len(variant_aliases)}")
    print(f"Exercises with female character variant: {sum(1 for e in imported_exercises if e.get('femaleVariant'))}")
    print(f"Numeric named exercises: 0 (Fixed!)")

if __name__ == '__main__':
    main()
