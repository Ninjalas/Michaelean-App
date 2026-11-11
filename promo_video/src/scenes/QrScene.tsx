import {Audio} from '@remotion/media';
import {AbsoluteFill, interpolate, random, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {Background} from '../Background';
import {Burst, camera, float, punch, Rays, shake, Shockwave} from '../Effects';
import {Crop, IMG_H, Phone, PHONE_H, s, SCREEN_W, shotToPhone} from '../Phone';
import {BEAT, C, clamp, out, SHOT_H, SHOT_W} from '../theme';
import {Words} from '../Words';

const PHONE = {left: 1150, top: (1080 - PHONE_H) / 2};
const TAB = {x: 0.5, y: 0.9475}; // Student Life tab, as a fraction of the screenshot
const SHEET_TOP = 0.4; // where the QR sheet's top edge sits in qr.png
const QR = {x: 585, y: 1707}; // center of the code in qr.png
const toCanvas = (x: number, y: number) => {
  const p = shotToPhone(x, y);
  return {x: PHONE.left + p.x, y: PHONE.top + p.y};
};
const qrCenter = toCanvas(QR.x, QR.y);
const CLOSE = 1.9; // zoom on the code
// When zoomed, keep the phone's left edge at x ≥ 1060, clear of the caption.
const keepClear = (f: {x: number; y: number}, z: number) => ({x: 1060 + (f.x - PHONE.left) * z, y: 540});
const qrOnScreen = {x: keepClear(qrCenter, CLOSE).x, y: 640}; // where the code sits once zoomed

// 6–10 s, the signature shot: hold Student Life and the QR pops up.
export const QrScene = () => {
  const frame = useCurrentFrame();
  const press = 30; // finger goes down (release lands on 8.0 s, the music's drop)
  const release = press + 2 * BEAT; // code appears
  const closeUp = release + 4; // camera pushes in on the code as the sheet rises, so its small print never settles in view

  const holdP = interpolate(frame, [press, release], [0, 1], clamp);
  const sheet = interpolate(frame, [release, release + 9], [1, 0], {...clamp, easing: out});
  const fl = float(frame, 3);
  // Tension: the phone trembles more the longer the finger holds.
  const holding = frame >= press && frame < release;
  const tremble = holding ? holdP * 4 : 0;
  const jx = holding ? (random(`jx${frame}`) - 0.5) * tremble : 0;
  const jy = holding ? (random(`jy${frame}`) - 0.5) * tremble : 0;
  const sh = shake(frame, release, 10, 18);
  const ry = interpolate(frame, [0, 110], [-16, -4], clamp) + fl.ry;
  const cam = camera(frame, [
    {at: 0, zoom: 1},
    {at: 10, zoom: 2.3, x: TAB.x * SHOT_W, y: TAB.y * SHOT_H}, // onto the tab
    {at: release, zoom: 1},
    {at: closeUp, zoom: CLOSE, x: QR.x, y: QR.y - 60, ty: 640}, // onto the code; small print below stays out of frame
  ], toCanvas, keepClear);

  return (
    <AbsoluteFill style={{scale: String(punch(frame, [press, release, closeUp], 0.035) + frame * 0.0004), translate: `${sh.x}px ${sh.y}px`}}>
      <Background stops={[[0, C.black], [press, C.navy], [release, C.red]]} />
      {frame >= release && <Rays x={`${(qrOnScreen.x / 1920) * 100}%`} y={`${(qrOnScreen.y / 1080) * 100}%`} color="rgba(255,255,255,0.12)" speed={0.8} />}
      <Shockwave at={release} x={qrCenter.x} y={qrCenter.y} size={400} />
      <Burst at={release} x={qrCenter.x} y={qrCenter.y} count={36} reach={700} />
      <Shockwave at={closeUp + 6} x={qrOnScreen.x} y={qrOnScreen.y} size={500} color="rgba(255,255,255,0.6)" />

      <AbsoluteFill style={cam}>
        <Phone
          src="life" statusDim={1 - sheet} tilt={ry}
          style={{
            left: PHONE.left, top: PHONE.top,
            translate: `${fl.x + jx}px ${fl.y + jy + interpolate(frame, [0, 10], [700, 0], {...clamp, easing: out})}px`,
            transform: `perspective(2400px) rotateX(${fl.rx}deg) rotateY(${ry}deg) rotateZ(${fl.rz}deg)`,
          }}
        >
          {/* QR sheet: dim the page, slide the sheet up. */}
          <Crop src="qr" x={0} y={0} w={SHOT_W} h={SHOT_H * SHEET_TOP} scale={s} style={{left: 0, top: 0, opacity: 1 - sheet}} />
          <Crop src="qr" x={0} y={SHOT_H * SHEET_TOP} w={SHOT_W} h={SHOT_H * (1 - SHEET_TOP)} scale={s} style={{left: 0, top: IMG_H * SHEET_TOP + sheet * IMG_H * 0.7}} />
          {/* Finger hold on the tab, with a ring that fills. */}
          {frame >= press && frame < release + 2 && (
            <svg width={90} height={90} style={{position: 'absolute', left: TAB.x * SCREEN_W - 45, top: TAB.y * IMG_H - 50, scale: String(interpolate(frame, [press, press + 4], [1.6, 1], {...clamp, easing: out}))}}>
              <circle cx={45} cy={45} r={30} fill="rgba(36,42,94,0.25)" />
              <circle cx={45} cy={45} r={38} fill="none" stroke={C.red} strokeWidth={6} strokeDasharray={2 * Math.PI * 38} strokeDashoffset={(1 - holdP) * 2 * Math.PI * 38} transform="rotate(-90 45 45)" strokeLinecap="round" />
            </svg>
          )}
        </Phone>
      </AbsoluteFill>

      <div style={{position: 'absolute', left: 140, top: 330, width: 950}}>
        <Words color={C.white} size={170} words={[['Hold', 3], ['for', 8], ['\n', 99], ['your', release], ['QR.', release + 4]]} />
      </div>

      <Sequence from={0} layout="none"><Audio src={staticFile('sfx/whoosh.wav')} volume={0.7} /></Sequence>
      <Sequence from={press} layout="none"><Audio src={staticFile('sfx/hold.wav')} volume={0.6} /></Sequence>
      <Sequence from={release} layout="none"><Audio src={staticFile('sfx/impact.wav')} /></Sequence>
      <Sequence from={release} layout="none"><Audio src={staticFile('sfx/whoosh.wav')} volume={0.6} /></Sequence>
      <Sequence from={closeUp} layout="none"><Audio src={staticFile('sfx/ding.wav')} volume={0.7} /></Sequence>
    </AbsoluteFill>
  );
};
