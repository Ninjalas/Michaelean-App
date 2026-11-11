import {Audio} from '@remotion/media';
import {AbsoluteFill, Easing, Img, interpolate, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {Background, pick, type Stops} from './Background';
import {camera, type CamKey, float, punch, Shockwave} from './Effects';
import {Crop, IMG_H, Phone, PHONE_H, PHONE_W, s, SCREEN_W, shotToPhone} from './Phone';
import {C, clamp, out, SHOT_H, SHOT_W} from './theme';
import {Words} from './Words';

// A screen shown in the phone from frame `at`. `via` is how it arrives:
// push (slides in from the right, like opening a page), sheet (pop-up slides
// up; `sheetTop` is where its top edge sits, 0–1), fade, or cut.
export type Screen = {src: string; at: number; via?: 'push' | 'sheet' | 'fade' | 'cut'; sheetTop?: number; light?: boolean};
export type Tap = {at: number; x: number; y: number}; // screenshot px
export type Caption = {at: number; text: string; accent?: string; size?: number}; // '/' breaks the line
export type Pop = {at: number; until?: number; src: string; x: number; y: number; w: number; h: number; scale: number; to: {x: number; y: number}; rotate?: number};

const LIGHT = new Set<string>([C.white, C.page]);
const textOn = (bg: string) => (LIGHT.has(bg) ? C.ink : C.white);
const accentOn = (bg: string) => (LIGHT.has(bg) ? C.red : bg === C.red ? '#FFD2D5' : '#FF5A64');

const Sfx = ({at, name, volume = 1}: {at: number; name: string; volume?: number}) => (
  <Sequence from={at} layout="none"><Audio src={staticFile(`sfx/${name}.wav`)} volume={volume} /></Sequence>
);

// One screen layer inside the phone's image area.
const ScreenLayer = ({screen, next}: {screen: Screen; next?: Screen}) => {
  const frame = useCurrentFrame();
  const {at, via = 'cut', src} = screen;
  if (frame < at) return null;
  if (next && next.via !== 'sheet' && frame > next.at + 8) return null;
  const img = {position: 'absolute', left: 0, top: 0, width: SCREEN_W, height: IMG_H} as const;
  if (via === 'sheet') {
    const top = screen.sheetTop ?? 0.4;
    const p = interpolate(frame, [at, at + 9], [1, 0], {...clamp, easing: out});
    return (
      <>
        <Crop src={src} x={0} y={0} w={SHOT_W} h={SHOT_H * top} scale={s} style={{left: 0, top: 0, opacity: 1 - p}} />
        <Crop src={src} x={0} y={SHOT_H * top} w={SHOT_W} h={SHOT_H * (1 - top)} scale={s} style={{left: 0, top: IMG_H * top + p * IMG_H * 0.7}} />
      </>
    );
  }
  const enter = via === 'push' ? interpolate(frame, [at, at + 7], [SCREEN_W, 0], {...clamp, easing: out}) : 0;
  const leave = next?.via === 'push' ? interpolate(frame, [next.at, next.at + 7], [0, -0.3 * SCREEN_W], {...clamp, easing: out}) : 0;
  const opacity = via === 'fade' ? interpolate(frame, [at, at + 4], [0, 1], clamp) : 1;
  return (
    <div style={{...img, translate: `${enter + leave}px 0px`, opacity, boxShadow: via === 'push' ? '-20px 0 40px rgba(0,0,0,0.15)' : undefined}}>
      <Img src={staticFile(`screens/${src}.png`)} style={img} />
    </div>
  );
};

// Finger tap: a dot that lands, and a ring that spreads.
const TapMark = ({tap}: {tap: Tap}) => {
  const frame = useCurrentFrame();
  const t = frame - tap.at;
  if (t < 0 || t > 10) return null;
  const x = tap.x * s;
  const y = tap.y * s;
  return (
    <>
      <div style={{position: 'absolute', left: x - 22, top: y - 22, width: 44, height: 44, borderRadius: 22, background: 'rgba(36,42,94,0.35)', scale: String(interpolate(t, [0, 3], [1.5, 1], {...clamp, easing: out})), opacity: interpolate(t, [6, 10], [1, 0], clamp)}} />
      <div style={{position: 'absolute', left: x - 22, top: y - 22, width: 44, height: 44, borderRadius: 22, border: `3px solid ${C.red}`, scale: String(interpolate(t, [0, 10], [1, 2.4], {...clamp, easing: out})), opacity: interpolate(t, [0, 10], [1, 0], clamp)}} />
    </>
  );
};

export const FeatureScene = ({bg, captions, screens, taps = [], pops = [], side = 'right', enter = 'depth', cam = [{at: 0, zoom: 1}], depthPulse = false, flyOut}: {
  bg: Stops<string>;
  captions: Caption[];
  screens: Screen[];
  taps?: Tap[];
  pops?: Pop[];
  side?: 'left' | 'right';
  enter?: 'bottom' | 'side' | 'depth' | 'none';
  cam?: CamKey[]; // camera zooms onto screenshot points (see Effects.camera)
  depthPulse?: boolean; // each new screen punches toward the camera (montage)
  flyOut?: number; // frame where the phone flies into the camera and fills the frame
}) => {
  const frame = useCurrentFrame();
  const bgNow = pick(frame, bg);
  const phone = {left: side === 'right' ? 1180 : 300, top: (1080 - PHONE_H) / 2};
  const textLeft = side === 'right' ? 140 : 860;
  const current = pick(frame, screens.map((sc) => [sc.at, sc] as [number, Screen]));
  const base = current.via === 'sheet' ? screens[screens.indexOf(current) - 1] : current;
  const dir = side === 'right' ? -1 : 1;

  const inP = enter === 'none' ? 1 : interpolate(frame, [0, enter === 'depth' ? 12 : 10], [0, 1], {...clamp, easing: out});
  const fl = float(frame, side === 'right' ? 0 : 2);
  const fromX = enter === 'side' ? -dir * 900 * (1 - inP) : 0;
  const fromY = enter === 'bottom' ? 800 * (1 - inP) : 0;
  const depthIn = enter === 'depth' ? interpolate(inP, [0, 1], [0.3, 1]) : 1;
  const out_ = flyOut === undefined ? 0 : interpolate(frame, [flyOut, flyOut + 10], [0, 1], {...clamp, easing: Easing.in(Easing.cubic)});
  // Phone bumps on taps and screen changes; montage screens punch toward the camera.
  const hits = [...taps.map((t) => t.at), ...screens.slice(1).map((sc) => sc.at)];
  const scale = depthIn * punch(frame, hits, depthPulse ? 0.16 : 0.03) * (1 + 3.5 * out_);
  const blur = (1 - inP) * 12 + out_ * 14;
  // The phone turns from angled to straight-on over the scene; the gloss follows.
  const ry = dir * interpolate(frame, [0, 110], [16, 4], clamp) + fl.ry;
  const camK = punch(frame, bg.slice(1).map(([at]) => at), 0.03) + frame * 0.0004;
  const toCanvas = (x: number, y: number) => {
    const p = shotToPhone(x, y);
    return {x: phone.left + p.x, y: phone.top + p.y};
  };
  // When zoomed, place the phone so its inner edge stops short of the captions:
  // phone on the right keeps its left edge at x ≥ 1090; on the left, its right edge ≤ 820.
  const keepClear = (focus: {x: number; y: number}, z: number) => ({
    x: side === 'right' ? 1090 + (focus.x - phone.left) * z : 820 - (phone.left + PHONE_W - focus.x) * z,
    y: 540,
  });

  return (
    <AbsoluteFill style={{scale: String(camK)}}>
      <Background stops={bg} />

      <AbsoluteFill style={camera(frame, cam, toCanvas, keepClear)}>
        <Phone
          src={screens[0].src}
          tilt={ry}
          statusBg={base.light ? C.page : C.navy}
          darkStatus={!!base.light}
          statusDim={current.via === 'sheet' ? interpolate(frame, [current.at, current.at + 9], [0, 1], clamp) : 0}
          style={{
            left: phone.left, top: phone.top,
            translate: `${fromX + fl.x}px ${fromY + fl.y}px`,
            transform: `perspective(2400px) rotateX(${fl.rx}deg) rotateY(${ry}deg) rotateZ(${interpolate(inP, [0, 1], [dir * -12, 0]) + fl.rz}deg) scale(${scale})`,
            filter: blur > 0.2 ? `blur(${blur}px)` : undefined,
            opacity: interpolate(frame, [0, 3], [0, 1], clamp) * (1 - interpolate(out_, [0.75, 1], [0, 1], clamp)),
          }}
        >
          {screens.slice(1).map((sc, i) => <ScreenLayer key={sc.at} screen={sc} next={screens[i + 2]} />)}
          {taps.map((t) => <TapMark key={t.at} tap={t} />)}
        </Phone>
      </AbsoluteFill>

      {pops.map((p) => {
        const start = toCanvas(p.x, p.y);
        const q = interpolate(frame, [p.at, p.at + 10], [0, 1], {...clamp, easing: out});
        const gone = p.until === undefined ? 0 : interpolate(frame, [p.until, p.until + 5], [0, 1], clamp);
        if (frame < p.at || gone >= 1) return null;
        const hover = Math.sin((frame - p.at) / 14) * 8; // keeps floating after it lands
        return (
          <div key={p.at}>
            <Shockwave at={p.at + 6} x={p.to.x + (p.w * s * p.scale) / 2} y={p.to.y + (p.h * s * p.scale) / 2} size={300} color="rgba(255,255,255,0.7)" />
            <Crop
              src={p.src} x={p.x} y={p.y} w={p.w} h={p.h}
              scale={s * interpolate(q, [0, 1], [1, p.scale])}
              style={{
                left: interpolate(q, [0, 1], [start.x + fl.x, p.to.x]),
                top: interpolate(q, [0, 1], [start.y + fl.y, p.to.y]),
                rotate: `${(p.rotate ?? -3) * q}deg`,
                opacity: 1 - gone,
                translate: `0px ${hover * q - 60 * gone}px`,
                borderRadius: 18 * s * p.scale,
                boxShadow: '0 40px 90px rgba(0,0,0,0.45), 0 0 60px rgba(255,255,255,0.15), inset 0 0 0 1.5px rgba(255,255,255,0.6)',
              }}
            >
              {/* Glossy card surface, tilted with the card. */}
              <div style={{position: 'absolute', inset: 0, background: `linear-gradient(115deg, rgba(255,255,255,0.35) 0%, rgba(255,255,255,0) 30%, rgba(255,255,255,0) ${70 + hover}%, rgba(255,255,255,0.18) 100%)`}} />
            </Crop>
          </div>
        );
      })}

      {captions.map((cap, i) => {
        const next = captions[i + 1];
        const leave = next ? interpolate(frame, [next.at - 3, next.at + 1], [0, 1], clamp) : 0;
        if (frame < cap.at || leave >= 1) return null;
        const words = cap.text.split(' ').flatMap((w) => (w === '/' ? [['\n', 900] as [string, number]] : [[w, 0] as [string, number]]));
        let k = 0;
        const timed = words.map(([w]) => [w, w === '\n' ? 900 + k : 3 * k++] as [string, number]);
        return (
          <div key={cap.at} style={{position: 'absolute', left: textLeft, top: 0, bottom: 0, width: 920, display: 'flex', alignItems: 'center', translate: `0px ${-70 * leave}px`, opacity: (1 - leave) * (1 - out_)}}>
            <Sequence from={cap.at} layout="none">
              <Words color={textOn(bgNow)} size={cap.size ?? 150} words={timed} accent={cap.accent ? {word: cap.accent, color: accentOn(bgNow)} : undefined} />
            </Sequence>
          </div>
        );
      })}

      {enter !== 'none' && <Sfx at={0} name="whoosh" volume={0.7} />}
      {bg.slice(1).map(([at]) => <Sfx key={`k${at}`} at={at} name="kick" volume={0.7} />)}
      {taps.map((t) => <Sfx key={`t${t.at}`} at={t.at} name="click" volume={0.8} />)}
      {screens.slice(1).filter((sc) => sc.via === 'push' || sc.via === 'sheet').map((sc) => <Sfx key={`w${sc.at}`} at={sc.at} name="whoosh" volume={0.35} />)}
      {cam.slice(1).filter((k) => k.zoom > 1).map((k) => <Sfx key={`z${k.at}`} at={k.at} name="whoosh" volume={0.3} />)}
      {pops.map((p) => <Sfx key={`p${p.at}`} at={p.at} name="pop" />)}
      {flyOut !== undefined && <Sfx at={flyOut} name="whoosh_long" volume={0.8} />}
    </AbsoluteFill>
  );
};
