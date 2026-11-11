import {AbsoluteFill, random, useCurrentFrame} from 'remotion';
import {flash, Rays} from './Effects';
import {C} from './theme';

export type Stops<T> = [number, T][]; // [from frame, value], in order

// The value whose stop was reached last (hard cuts, like the reference).
export const pick = <T,>(frame: number, stops: Stops<T>): T =>
  stops.reduce((cur, [at, v]) => (frame >= at ? v : cur), stops[0][1]);

const LIGHT = new Set<string>([C.white, C.page]);

// Glow colors per background; maroon on navy echoes the app's header.
const GLOW: Record<string, [string, string]> = {
  [C.navy]: ['rgba(170,45,95,0.75)', 'rgba(70,90,220,0.55)'],
  [C.black]: ['rgba(50,60,150,0.85)', 'rgba(179,36,46,0.45)'],
  [C.night]: ['rgba(120,20,45,0.55)', 'rgba(36,42,110,0.6)'], // deep maroon and navy, low light
  [C.red]: ['rgba(255,140,120,0.6)', 'rgba(120,10,30,0.7)'],
  [C.white]: ['rgba(36,42,94,0.10)', 'rgba(179,36,46,0.07)'],
  [C.page]: ['rgba(36,42,94,0.12)', 'rgba(179,36,46,0.08)'],
};

const Glow = ({x, y, size, color, opacity = 1}: {x: number; y: number; size: number; color: string; opacity?: number}) => (
  <div style={{position: 'absolute', left: x - size / 2, top: y - size / 2, width: size, height: size, borderRadius: '50%', background: `radial-gradient(circle, ${color} 0%, transparent 62%)`, opacity}} />
);

// Background that cuts color on the beat, with drifting glows, light rays,
// floating bokeh, a vignette, and a flash on every cut.
export const Background = ({stops, rays = true}: {stops: Stops<string>; rays?: boolean}) => {
  const frame = useCurrentFrame();
  const bg = pick(frame, stops);
  const light = LIGHT.has(bg);
  const [g1, g2] = GLOW[bg] ?? ['rgba(255,255,255,0.1)', 'rgba(255,255,255,0.05)'];
  const t = frame / 30;
  const lastCut = stops.filter(([at]) => at > 0 && frame >= at).pop()?.[0];
  return (
    <AbsoluteFill style={{background: bg, overflow: 'hidden'}}>
      <Glow x={1500 + Math.sin(t * 1.1) * 260} y={150 + Math.cos(t * 0.9) * 160} size={1500} color={g1} />
      <Glow x={300 + Math.cos(t * 0.8) * 240} y={900 + Math.sin(t * 1.2) * 140} size={1300} color={g2} />
      <Glow x={960 + Math.sin(t * 0.6) * 400} y={540 + Math.cos(t * 0.7) * 200} size={900} color={g1} opacity={0.45} />
      {rays && <Rays x="80%" y="10%" color={light ? 'rgba(36,42,94,0.05)' : 'rgba(255,255,255,0.07)'} />}
      {/* Bokeh: soft dots drifting up. */}
      {Array.from({length: 18}, (_, i) => {
        const size = 8 + random(`bs${i}`) * 38;
        const speed = 0.6 + random(`bv${i}`) * 1.6;
        const y = ((random(`by${i}`) * 1300 - frame * speed) % 1300 + 1300) % 1300 - 110;
        const x = random(`bx${i}`) * 1920 + Math.sin(t + i) * 20;
        return (
          <div key={i} style={{position: 'absolute', left: x, top: y, width: size, height: size, borderRadius: '50%', background: light ? 'rgba(36,42,94,0.25)' : 'rgba(255,255,255,0.6)', filter: `blur(${2 + random(`bb${i}`) * 6}px)`, opacity: 0.08 + random(`bo${i}`) * 0.25}} />
        );
      })}
      <AbsoluteFill style={{background: `radial-gradient(ellipse at center, transparent 50%, ${light ? 'rgba(36,42,94,0.10)' : 'rgba(0,0,0,0.45)'} 100%)`}} />
      {lastCut !== undefined && (
        <AbsoluteFill style={{background: '#fff', opacity: flash(frame, lastCut, 0.35)}} />
      )}
    </AbsoluteFill>
  );
};
