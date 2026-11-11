import {interpolate, random, useCurrentFrame} from 'remotion';
import {clamp, out} from './theme';

// A small float so a phone never looks frozen (the big moves come from the camera).
export const float = (frame: number, seed = 0) => ({
  x: Math.sin(frame / 38 + seed) * 8,
  y: Math.sin(frame / 26 + seed * 2) * 12,
  rx: Math.cos(frame / 31 + seed) * 3,
  ry: Math.sin(frame / 34 + seed) * 4,
  rz: Math.sin(frame / 47 + seed) * 1.5,
});

// Camera keyframe: from frame `at`, zoom to `zoom` with the screenshot point
// (x, y) brought to the canvas point (tx, ty). zoom 1 with no point = the
// normal full view. Each move takes 9 frames, snappy ease-out.
export type CamKey = {at: number; zoom: number; x?: number; y?: number; tx?: number; ty?: number};

// Returns a CSS transform for a full-canvas layer holding the phone.
// `toCanvas` turns a screenshot point into canvas px (phone position included).
// `target` says where the focus point should land when a key gives no tx/ty;
// as a function it can keep the zoomed phone clear of the captions.
type Pt = {x: number; y: number};
export const camera = (frame: number, keys: CamKey[], toCanvas: (x: number, y: number) => Pt, target: Pt | ((focus: Pt, zoom: number) => Pt)) => {
  const state = (k: CamKey) => {
    if (k.x === undefined || k.y === undefined) return {z: k.zoom, dx: 0, dy: 0};
    const f = toCanvas(k.x, k.y);
    const d = typeof target === 'function' ? target(f, k.zoom) : target;
    const t = {x: k.tx ?? d.x, y: k.ty ?? d.y};
    return {z: k.zoom, dx: t.x - f.x * k.zoom, dy: t.y - f.y * k.zoom};
  };
  let i = 0;
  keys.forEach((k, j) => {
    if (frame >= k.at) i = j;
  });
  const from = state(keys[Math.max(0, i - 1)]);
  const to = state(keys[i]);
  const p = i === 0 ? 1 : interpolate(frame, [keys[i].at, keys[i].at + 9], [0, 1], {...clamp, easing: out});
  const lerp = (a: number, b: number) => a + (b - a) * p;
  return {transformOrigin: '0 0', transform: `translate(${lerp(from.dx, to.dx)}px, ${lerp(from.dy, to.dy)}px) scale(${lerp(from.z, to.z)})`};
};

// 0→1→0 bump starting at each hit frame (fast rise, quick decay).
const bump = (t: number) => (t < 0 ? 0 : t < 2 ? t / 2 : Math.max(0, 1 - (t - 2) / 8));
export const punch = (frame: number, hits: number[], amount = 0.04) =>
  1 + hits.reduce((a, h) => a + amount * bump(frame - h), 0);

// White-flash strength: `peak` at frame `at`, fading out over `dur`; 0 before `at`.
export const flash = (frame: number, at: number, peak: number, dur = 6) =>
  frame < at ? 0 : interpolate(frame - at, [0, dur], [peak, 0], clamp);

// Camera shake that dies out over `dur` frames.
export const shake = (frame: number, at: number, dur = 10, amp = 16) => {
  const t = frame - at;
  if (t < 0 || t > dur) return {x: 0, y: 0};
  const k = amp * (1 - t / dur);
  return {x: (random(`sx${at}-${t}`) - 0.5) * 2 * k, y: (random(`sy${at}-${t}`) - 0.5) * 2 * k};
};

// A ring that bursts outward from a point.
export const Shockwave = ({at, x, y, color = 'rgba(255,255,255,0.9)', size = 260, dur = 18}: {at: number; x: number; y: number; color?: string; size?: number; dur?: number}) => {
  const t = useCurrentFrame() - at;
  if (t < 0 || t > dur) return null;
  return (
    <div
      style={{
        position: 'absolute', left: x - size / 2, top: y - size / 2, width: size, height: size, borderRadius: '50%',
        border: `${interpolate(t, [0, dur], [14, 1], clamp)}px solid ${color}`,
        boxShadow: `0 0 40px ${color}`,
        scale: String(interpolate(t, [0, dur], [0.2, 4.5], {...clamp, easing: out})),
        opacity: interpolate(t, [0, dur], [1, 0], clamp),
      }}
    />
  );
};

// Sparks flying out from a point.
export const Burst = ({at, x, y, count = 28, color = '#fff', dur = 24, reach = 520}: {at: number; x: number; y: number; count?: number; color?: string; dur?: number; reach?: number}) => {
  const t = useCurrentFrame() - at;
  if (t < 0 || t > dur) return null;
  const p = interpolate(t, [0, dur], [0, 1], {...clamp, easing: out});
  return (
    <>
      {Array.from({length: count}, (_, i) => {
        const a = random(`ba${at}-${i}`) * Math.PI * 2;
        const d = (0.35 + random(`bd${at}-${i}`) * 0.65) * reach * p;
        const r = 3 + random(`br${at}-${i}`) * 7;
        return (
          <div key={i} style={{position: 'absolute', left: x + Math.cos(a) * d - r, top: y + Math.sin(a) * d - r, width: r * 2, height: r * 2, borderRadius: r, background: color, boxShadow: `0 0 ${r * 3}px ${color}`, opacity: 1 - p}} />
        );
      })}
    </>
  );
};

// Slowly turning light rays from a point, fading toward the edges.
export const Rays = ({x = '50%', y = '50%', color = 'rgba(255,255,255,0.10)', speed = 0.35, opacity = 1}: {x?: string; y?: string; color?: string; speed?: number; opacity?: number}) => {
  const frame = useCurrentFrame();
  const mask = `radial-gradient(circle at ${x} ${y}, black 0%, transparent 70%)`;
  return (
    <div
      style={{
        position: 'absolute', inset: 0, opacity,
        background: `repeating-conic-gradient(from ${frame * speed}deg at ${x} ${y}, ${color} 0deg 5deg, transparent 5deg 20deg)`,
        maskImage: mask, WebkitMaskImage: mask,
      }}
    />
  );
};

// A bright diagonal band that sweeps across its parent (parent clips it).
export const Shine = ({at, dur = 14, strength = 0.55}: {at: number; dur?: number; strength?: number}) => {
  const t = useCurrentFrame() - at;
  if (t < 0 || t > dur) return null;
  return (
    <div
      style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `linear-gradient(105deg, transparent 35%, rgba(255,255,255,${strength}) 50%, transparent 65%)`,
        translate: `${interpolate(t, [0, dur], [-110, 110], clamp)}% 0px`,
      }}
    />
  );
};
