import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';

const $ = id => document.getElementById(id);
let renderer, scene, camera, controls, mixer, model, actions = [], meshes = [];
let duration = 0, time = 0, playing = false, loop = true, rate = 1, ready = false;
let reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
let active = true, disposed = false, frame = 0, last = 0, view = 'side', error = null;
let config = {}, loadGeneration = 0;
const target = new THREE.Vector3();
let radius = 2.6, baseRadius = 2.6;
function send(type, data = {}) { window.TrainerBridge?.postMessage(JSON.stringify({type, ...data})); }
function phase() {
  const p = duration ? time / duration : 0;
  return [...(config.phases || [])].reverse().find(x => p >= x.at)?.label || 'Inspect movement';
}
function notify() {
  $('play').textContent = playing ? 'Pause' : 'Play';
  $('timeline').value = duration ? Math.round(time / duration * 1000) : 0;
  $('timeline').setAttribute('aria-valuetext', `${phase()}, ${time.toFixed(1)} seconds`);
  $('phase').textContent = phase();
}
function render() { if (renderer && !disposed) renderer.render(scene, camera); }
function schedule() { if (!frame && active && !disposed) frame = requestAnimationFrame(tick); }
function tick(now) {
  frame = 0;
  const dt = last ? Math.min((now - last) / 1000, .1) : 0;
  last = now;
  if (playing && ready) {
    time += dt * rate;
    if (time >= duration) { if (loop) time %= duration; else { time = duration; playing = false; } }
    applyTime(); notify();
  }
  controls?.update(); render();
  if (playing) schedule(); else last = 0;
}
function applyTime() {
  // Explicitly sample every clip. Seeking must move the mesh and the armature together.
  for (const action of actions) { action.paused = false; action.enabled = true; action.time = time; }
  mixer?.update(0); model?.updateMatrixWorld(true);
}
function pause() { playing = false; last = 0; notify(); schedule(); }
function seek(value) { pause(); time = Math.max(0, Math.min(duration, value)); applyTime(); notify(); schedule(); }
function play() { if (!ready || reduced || !active || error) return; if(time >= duration) time = 0; playing = true; last = 0; notify(); schedule(); }
function setView(name) {
  view = name;
  const offsets = {front: [0, .65, 1], side: [1, .65, .15], back: [0, .65, -1]};
  const offset = new THREE.Vector3(...offsets[name]).normalize().multiplyScalar(radius);
  camera.position.copy(target).add(offset); controls.target.copy(target); controls.update();
  document.querySelectorAll('[data-view]').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.view === name)));
  schedule();
}
function resize() {
  if (!renderer || disposed) return;
  const bounds = $('stage').getBoundingClientRect();
  const oldRadius = radius;
  radius = baseRadius * Math.max(1, bounds.height / bounds.width);
  if(ready && oldRadius !== radius) {camera.position.sub(target).multiplyScalar(radius / oldRadius).add(target); controls.minDistance = radius * .5; controls.maxDistance = radius * 2.2;}
  renderer.setSize(bounds.width, bounds.height); camera.aspect = bounds.width / bounds.height;
  camera.updateProjectionMatrix(); schedule();
}
function fail(message) {
  error = message; ready = false; pause();
  $('status').textContent = message; $('status').className = 'error';
  document.querySelectorAll('button,select,input').forEach(el => el.disabled = true);
  send('error', {message});
}
function clearModel() {
  mixer?.stopAllAction(); if(model) mixer?.uncacheRoot(model);
  if(model) { scene.remove(model); model.traverse(o => { if(o.geometry) o.geometry.dispose(); if(o.material) for(const m of Array.isArray(o.material)?o.material:[o.material]) m.dispose(); }); }
  model = null; mixer = null; actions = []; meshes = [];
}
async function load(base64, options) {
  const generation = ++loadGeneration;
  ready = false; pause(); config = options; error = null;
  $('status').textContent = 'Loading human model…';
  try {
    if(!renderer) init();
    clearModel();
    const bytes = Uint8Array.from(atob(base64), ch => ch.charCodeAt(0));
    const gltf = await new GLTFLoader().parseAsync(bytes.buffer, '');
    if(disposed || generation !== loadGeneration) return;
    const clips = options.clips.map(name => gltf.animations.find(c => c.name === name));
    if(clips.some(c => !c) || !clips.length) throw new Error('Required exercise animation is missing.');
    model = gltf.scene;
    model.traverse(o => {
      if(o.isSkinnedMesh) {
        meshes.push(o); o.frustumCulled = false;
        const original = o.geometry.getAttribute('color');
        o.userData.muscleColors = original;
        const position = o.geometry.getAttribute('position');
        const colors = new Float32Array(position.count * 3);
        const skin = new THREE.Color(0xb99980), fabric = new THREE.Color(0x153745), shoe = new THREE.Color(0x222d36);
        for(let i=0;i<position.count;i++) {
          const y=position.getY(i), x=position.getX(i);
          const c = y < .09 ? shoe : y > .62 && y < .99 && Math.abs(x)<.24 ? fabric : skin;
          c.toArray(colors,i*3);
        }
        o.userData.baseColors = new THREE.BufferAttribute(colors,3);
        o.geometry.setAttribute('color',o.userData.baseColors);
        o.material = new THREE.MeshStandardMaterial({color: 0xffffff, roughness: .63, metalness: 0, vertexColors: true});
        o.castShadow = true; o.receiveShadow = true;
      }
    });
    if(!meshes.length) throw new Error('Model has no skinned character mesh.');
    scene.add(model); mixer = new THREE.AnimationMixer(model);
    actions = clips.map(c => { const a = mixer.clipAction(c); a.setLoop(THREE.LoopOnce, 1); a.clampWhenFinished = true; a.play(); return a; });
    duration = Math.max(...clips.map(c => c.duration));
    if(!Number.isFinite(duration) || duration <= 0) throw new Error('Animation has no duration.');
    time = Math.max(0, Math.min(duration, options.startTime || 0)); applyTime();
    const box = new THREE.Box3().setFromObject(model, true);
    box.getCenter(target); target.y = Math.max(.2, target.y);
    const size = box.getSize(new THREE.Vector3());
    baseRadius = Math.max(size.x,size.y,size.z) * 1.8; radius = baseRadius * Math.max(1, 340 / $('stage').clientWidth);
    controls.minDistance = radius * .5; controls.maxDistance = radius * 2.2;
    setView('side'); ready = true;
    $('fullscreen').hidden = !!options.fullscreen;
    if(options.fullscreen) $('stage').style.height = 'max(240px, calc(100vh - 310px))';
    $('status').textContent = '';
    document.querySelectorAll('button,select,input').forEach(el => el.disabled = false);
    setReduced(reduced); notify(); resize();
    send('ready', {duration, clips: clips.map(c => c.name), skinnedMeshes: meshes.length});
  } catch(e) { fail(`3D unavailable: ${e.message}`); }
}
function setReduced(value) { reduced = value; if(reduced) pause(); $('play').disabled = reduced || !ready; $('replay').disabled = reduced || !ready; $('motion-note').textContent = reduced ? 'Reduced motion: use the position slider to inspect poses. Technical preview; technique review pending.' : 'Animated anatomical model · Technical preview. Independent technique review is pending.'; }
function setActive(value) { active = value; if(!active) { pause(); cancelAnimationFrame(frame); frame = 0; } else schedule(); }
function init() {
  renderer = new THREE.WebGLRenderer({antialias:true, alpha:true, powerPreference:'low-power'});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
  renderer.setClearColor(0x000000, 0); renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  $('stage').prepend(renderer.domElement);
  renderer.domElement.addEventListener('webglcontextlost', e => { e.preventDefault(); fail('3D graphics interrupted. Return to the guide and retry.'); });
  scene = new THREE.Scene();
  scene.add(new THREE.HemisphereLight(0xdaf5ff,0x22323b,2.2));
  const key = new THREE.DirectionalLight(0xffe9d5,3.2); key.position.set(2,4,3); key.castShadow = true; key.shadow.mapSize.set(1024,1024); key.shadow.camera.left=-3;key.shadow.camera.right=3; key.shadow.camera.top=3; key.shadow.camera.bottom=-3; key.shadow.bias=-.0005; scene.add(key);
  const rim = new THREE.DirectionalLight(0x48eee1,2.4); rim.position.set(-2,2,-2); scene.add(rim);
  const floor = new THREE.Mesh(new THREE.CircleGeometry(1.65,80), new THREE.MeshStandardMaterial({color:0x193c49,roughness:.85})); floor.rotation.x=-Math.PI/2; floor.position.y=-.015;floor.receiveShadow=true;scene.add(floor);
  const ring = new THREE.Mesh(new THREE.RingGeometry(1.62,1.63,96), new THREE.MeshBasicMaterial({color:0x45bdba,side:THREE.DoubleSide}));ring.rotation.x=-Math.PI/2;ring.position.y=-.012;scene.add(ring);
  camera=new THREE.PerspectiveCamera(38,1,.01,40);
  controls=new OrbitControls(camera,renderer.domElement);controls.enablePan=false; controls.maxPolarAngle=Math.PI*.49; controls.addEventListener('change',schedule);
  resize();
}
function zoom(factor) { camera.position.sub(controls.target).multiplyScalar(factor).clampLength(controls.minDistance,controls.maxDistance).add(controls.target);controls.update();schedule(); }
function dispose() { if(disposed)return; pause(); disposed=true; ++loadGeneration;cancelAnimationFrame(frame);clearModel();controls?.dispose();scene?.traverse(o=>{o.geometry?.dispose();if(o.material)o.material.dispose();});renderer?.dispose();renderer?.forceContextLoss();window.removeEventListener('resize',resize); }
$('play').onclick=()=>playing?pause():play();
$('replay').onclick=()=>{seek(0);play();};
$('timeline').oninput=e=>seek(Number(e.target.value)/1000*duration);
$('speed').onchange=e=>rate=Number(e.target.value);
$('loop').onchange=e=>loop=e.target.checked;
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>setView(b.dataset.view));
$('zoom-in').onclick=()=>zoom(.85);$('zoom-out').onclick=()=>zoom(1.18);
$('highlight').onchange=e=>{for(const mesh of meshes){mesh.geometry.setAttribute('color', e.target.checked ? mesh.userData.muscleColors : mesh.userData.baseColors);}$('muscle-note').hidden=!e.target.checked;schedule();};
$('fullscreen').onclick=()=>{pause();send('fullscreen',{time});};
window.addEventListener('resize',resize);
document.addEventListener('visibilitychange',()=>setActive(!document.hidden));
window.addEventListener('pagehide',dispose);
window.fitforge = {load,pause,seek,setActive,setReduced,dispose,
  snapshot:()=>({ready,time,duration,playing,view,error,skinnedMeshes:meshes.length, camera:camera?.position.toArray(), bones:meshes[0]?.skeleton.bones.map(b=>new THREE.Vector3().setFromMatrixPosition(b.matrixWorld).toArray())})};
send('boot');
