import type {CSSProperties, ReactNode} from 'react';
import {Img, interpolate, staticFile} from 'remotion';
import {body, SHOT_H, SHOT_W} from './theme';

// iPhone-style phone: titanium edge, black bezel, Dynamic Island, status bar,
// side buttons. No Apple logo or name.
export const SCREEN_W = 380;
export const s = SCREEN_W / SHOT_W; // screenshot px → phone px
export const IMG_H = Math.round(SHOT_H * s); // 822
export const STATUS = 46; // status bar above the app screenshot
export const SCREEN_H = STATUS + IMG_H;
const EDGE = 5; // titanium band
const BEZEL = 11; // black border inside it
export const INSET = EDGE + BEZEL; // phone edge → screen edge
export const PHONE_W = SCREEN_W + INSET * 2;
export const PHONE_H = SCREEN_H + INSET * 2;

// A point in a screenshot (screenshot px) → position inside the phone (phone px).
export const shotToPhone = (x: number, y: number) => ({x: INSET + x * s, y: INSET + STATUS + y * s});

const titanium = 'linear-gradient(135deg, #8A8B90 0%, #3E3F44 22%, #6E6F75 50%, #2F3034 78%, #7D7E83 100%)';
// Silver edge: a bright band in a wide gradient; sliding it with the tilt
// makes the rim catch the light as the phone turns.
const silver = 'linear-gradient(120deg, #3A3B40 0%, #6E6F75 30%, #F4F5F8 46%, #FFFFFF 50%, #B8B9BE 56%, #4A4B50 75%, #2C2D31 100%)';

const Button = ({side, top, h}: {side: 'left' | 'right'; top: number; h: number}) => (
  <div style={{position: 'absolute', [side]: -4, top, width: 5, height: h, borderRadius: 3, background: titanium}} />
);

const StatusBar = ({dark}: {dark: boolean}) => {
  const ink = dark ? '#000' : '#fff';
  return (
    <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: STATUS, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 30px 0 40px', color: ink, fontFamily: body, fontWeight: 600, fontSize: 17}}>
      <span>9:41</span>
      <svg width={70} height={14} viewBox="0 0 70 14">
        {[0, 1, 2, 3].map((i) => <rect key={i} x={i * 5} y={10 - i * 3} width={3.4} height={4 + i * 3} rx={1} fill={ink} />)}
        <path d="M30 4.5a10 10 0 0 1 14 0l-1.6 1.6a7.7 7.7 0 0 0-10.8 0zM33.2 7.7a5.5 5.5 0 0 1 7.6 0L37 11.5z" fill={ink} />
        <rect x={48} y={1.5} width={19} height={11} rx={3} fill="none" stroke={ink} strokeOpacity={0.5} />
        <rect x={50} y={3.5} width={14} height={7} rx={1.5} fill={ink} />
        <rect x={68} y={5} width={1.6} height={4} rx={0.8} fill={ink} fillOpacity={0.5} />
      </svg>
    </div>
  );
};

export const Phone = ({src, statusBg = '#242A5E', darkStatus = false, statusDim = 0, tilt = 0, style, children}: {
  src: string;
  statusBg?: string; // matches the top of the screenshot
  darkStatus?: boolean;
  statusDim?: number; // 0–1, darkens the status bar with a pop-up's backdrop
  tilt?: number; // the phone's current Y rotation (deg); the gloss and rim follow it
  style?: CSSProperties;
  children?: ReactNode; // overlays, positioned in screenshot space (phone px)
}) => {
  const glossX = interpolate(tilt, [-25, 25], [-60, 60]); // % the gloss slides across the glass
  return (
  <div style={{position: 'absolute', width: PHONE_W, height: PHONE_H, ...style}}>
    {/* Soft floor shadow and halo. */}
    <div style={{position: 'absolute', left: PHONE_W * 0.08, right: PHONE_W * 0.08, bottom: -70, height: 70, borderRadius: '50%', background: 'rgba(0,0,0,0.45)', filter: 'blur(28px)'}} />
    <div style={{position: 'absolute', inset: -60, borderRadius: 120, background: 'radial-gradient(ellipse, rgba(255,255,255,0.18) 0%, transparent 70%)'}} />
    <Button side="left" top={150} h={34} />
    <Button side="left" top={215} h={62} />
    <Button side="left" top={290} h={62} />
    <Button side="right" top={240} h={96} />
    <div style={{position: 'absolute', inset: 0, borderRadius: 70, background: silver, backgroundSize: '320% 320%', backgroundPosition: `${50 - tilt * 2.2}% 50%`, padding: EDGE, boxShadow: '0 50px 100px rgba(0,0,0,0.38), 0 10px 25px rgba(0,0,0,0.25), inset 0 0 0 1px rgba(255,255,255,0.45)'}}>
      <div style={{width: '100%', height: '100%', borderRadius: 65, background: '#050506', padding: BEZEL}}>
        <div style={{position: 'relative', width: SCREEN_W, height: SCREEN_H, borderRadius: 54, overflow: 'hidden', background: statusBg}}>
          <StatusBar dark={darkStatus} />
          <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: STATUS, background: '#000', opacity: statusDim * 0.4}} />
          <div style={{position: 'absolute', left: 0, top: STATUS, width: SCREEN_W, height: IMG_H}}>
            <Img src={staticFile(`screens/${src}.png`)} style={{width: SCREEN_W, height: IMG_H, display: 'block'}} />
            {children}
          </div>
          {/* Dynamic Island */}
          <div style={{position: 'absolute', top: 11, left: '50%', marginLeft: -60, width: 120, height: 35, borderRadius: 20, background: '#000'}} />
          {/* Glass gloss: always on, slides as the phone turns, like glass catching light. */}
          <div style={{position: 'absolute', inset: 0, pointerEvents: 'none', background: 'linear-gradient(115deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.05) 28%, rgba(255,255,255,0) 40%)'}} />
          <div style={{position: 'absolute', top: '-20%', bottom: '-20%', left: '-30%', right: '-30%', pointerEvents: 'none', translate: `${glossX}% 0px`, background: 'linear-gradient(110deg, transparent 40%, rgba(255,255,255,0.20) 47%, rgba(255,255,255,0.07) 52%, transparent 58%)'}} />
          {/* Thin silver lining around the glass. */}
          <div style={{position: 'absolute', inset: 0, borderRadius: 54, pointerEvents: 'none', boxShadow: 'inset 0 0 0 1.5px rgba(255,255,255,0.35), inset 0 2px 6px rgba(255,255,255,0.25)'}} />
        </div>
      </div>
    </div>
  </div>
  );
};

// A rectangle cut out of a screenshot (in screenshot pixels), drawn at `scale`.
export const Crop = ({src, x, y, w, h, scale, style, children}: {src: string; x: number; y: number; w: number; h: number; scale: number; style?: CSSProperties; children?: ReactNode}) => (
  <div style={{position: 'absolute', width: w * scale, height: h * scale, overflow: 'hidden', ...style}}>
    <Img
      src={staticFile(`screens/${src}.png`)}
      style={{position: 'absolute', left: -x * scale, top: -y * scale, width: SHOT_W * scale, height: SHOT_H * scale, maxWidth: 'none'}}
    />
    {children}
  </div>
);
