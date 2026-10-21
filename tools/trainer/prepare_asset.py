"""Remove invalid empty morph animation exported by upstream Blender.
Usage: python3 tools/trainer/prepare_asset.py /path/to/original/push_up.glb
Does not modify vertex geometry, skin weights, bones, or skeletal keyframes.
"""
import hashlib
import json
from pathlib import Path
import struct
import sys

source = Path(sys.argv[1]).read_bytes()
assert source[:4] == b'glTF'
length = struct.unpack_from('<I', source, 12)[0]
document = json.loads(source[20:20+length])
removed = []
for animation in document['animations']:
    channels = []
    for channel in animation['channels']:
        target = channel['target']
        node = document['nodes'][target['node']]
        if target['path'] == 'weights' and not any(p.get('targets') for p in document['meshes'][node['mesh']]['primitives']):
            removed.append(animation.get('name'))
        else:
            channels.append(channel)
    animation['channels'] = channels
document['animations'] = [a for a in document['animations'] if a['channels']]
assert [a['name'] for a in document['animations']] == ['Human.rig']
encoded = json.dumps(document, separators=(',', ':')).encode()
encoded += b' ' * (-len(encoded) % 4)
tail = source[20+length:]
result = struct.pack('<III', 0x46546c67, 2, 20+len(encoded)+len(tail)) + struct.pack('<II',len(encoded),0x4e4f534a) + encoded + tail
root = Path(__file__).resolve().parents[2]
(root/'assets/trainer/push-up.glb').write_bytes(result)
manifest_path = root/'assets/trainer/manifest.json'
manifest = json.loads(manifest_path.read_text())
asset = manifest['assets'][0]
asset['clips'] = ['Human.rig']
asset['sourceSha256'] = hashlib.sha256(source).hexdigest()
asset['sha256'] = hashlib.sha256(result).hexdigest()
manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
print('Removed invalid non-skeletal morph tracks:', removed)
print('Output SHA256:', asset['sha256'])
