import {Audio} from '@remotion/media';
import {AbsoluteFill, interpolate, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {Background, pick} from '../Background';
import {float, punch, shake, Shockwave} from '../Effects';
import {Crop, Phone, PHONE_H, s, shotToPhone} from '../Phone';
import {BEAT, C, clamp, out} from '../theme';
import {Words} from '../Words';

const PHONE = {left: 1250, top: (1080 - PHONE_H) / 2};
const CARD = {x: 60, y: 753, w: 1050, h: 573}; // the Up next card in home.png
const cardStart = shotToPhone(CARD.x, CARD.y);

// 0–8 s: a problem students know, held long enough to land, then the navy Up next card.
export const Hook = () => {
  const frame = useCurrentFrame();
  const line2 = 2 * BEAT; // background flips light as the second line lands
  const again = line2 + 8; // "again?" lands hard
  const flip = 12.5 * BEAT; // navy sweeps in
  const cardAt = flip + 18;
  const fl = float(frame, 1);
  const ry = interpolate(frame, [flip, flip + 18], [-40, -14], {...clamp, easing: out}) + fl.ry;
  const sh = shake(frame, again, 8, 14);
  return (
    <AbsoluteFill style={{scale: String(punch(frame, [line2, again, flip, cardAt], 0.03) + frame * 0.0005)}}>
      <Background stops={[[0, C.black], [line2, C.page]]} />

      {/* The question, word by word, then it slides away. */}
      <div
        style={{
          position: 'absolute', left: 140, top: 330, width: 1500,
          translate: `${sh.x}px ${sh.y + interpolate(frame, [flip - 4, flip + 4], [0, -120], {...clamp, easing: out})}px`,
          opacity: interpolate(frame, [flip - 4, flip + 2], [1, 0], clamp),
        }}
      >
        <Words color={pick(frame, [[0, C.white], [line2, C.ink]])} size={170} words={[['Where’s', 0], ['my', 6], ['next', 10], ['\n', 999], ['class', line2], ['again?', again]]} accent={{word: 'again?', color: C.red}} />
      </div>

      {/* Navy sweeps in from the right edge. */}
      <AbsoluteFill style={{clipPath: `circle(${interpolate(frame, [flip - 4, flip + 8], [0, 120], {...clamp, easing: out})}% at 85% 50%)`}}>
        <Background stops={[[0, C.navy]]} />
      </AbsoluteFill>

      {/* Answer headline on navy. */}
      <Sequence from={flip + 6} layout="none">
        <div style={{position: 'absolute', left: 140, top: 340, width: 1050}}>
          <Words color={C.white} size={150} words={[['Always', 0], ['know', 4], ['\n', 98], ['what’s', 8], ['next.', 12]]} accent={{word: 'next.', color: '#FF5A64'}} />
        </div>
      </Sequence>

      {/* Phone swings in with Home. */}
      <Phone
        src="home"
        tilt={ry}
        style={{
          left: PHONE.left, top: PHONE.top,
          translate: `${fl.x}px ${fl.y}px`,
          transform: `perspective(2200px) translateX(${interpolate(frame, [flip, flip + 14], [900, 0], {...clamp, easing: out})}px) rotateX(${fl.rx}deg) rotateY(${ry}deg) rotateZ(${interpolate(frame, [flip, flip + 16], [10, 2], {...clamp, easing: out}) + fl.rz}deg)`,
          filter: `blur(${interpolate(frame, [flip, flip + 10], [12, 0], clamp)}px)`,
        }}
      />
      <Shockwave at={cardAt + 6} x={1370} y={600} size={320} />

      {/* The Up next card pops out of the phone toward the viewer. */}
      <Crop
        src="home" {...CARD}
        scale={s * interpolate(frame, [cardAt, cardAt + 10], [1, 1.8], {...clamp, easing: out})}
        style={{
          left: interpolate(frame, [cardAt, cardAt + 10], [PHONE.left + cardStart.x, 1070], {...clamp, easing: out}),
          top: interpolate(frame, [cardAt, cardAt + 10], [PHONE.top + cardStart.y, 420], {...clamp, easing: out}),
          opacity: interpolate(frame, [cardAt, cardAt + 1], [0, 1], clamp),
          rotate: `${interpolate(frame, [cardAt, cardAt + 12], [0, -4], {...clamp, easing: out})}deg`,
          translate: `0px ${Math.sin((frame - cardAt) / 12) * 8}px`,
          borderRadius: 18 * s * 1.8, boxShadow: '0 40px 90px rgba(0,0,0,0.5), 0 0 60px rgba(255,255,255,0.15)',
        }}
      >
        <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(115deg, rgba(255,255,255,0.35) 0%, rgba(255,255,255,0) 30%, rgba(255,255,255,0) 70%, rgba(255,255,255,0.18) 100%)'}} />
      </Crop>

      {[0, 6, 10, line2, again].map((f) => (
        <Sequence key={f} from={f} layout="none"><Audio src={staticFile('sfx/click.wav')} volume={0.6} /></Sequence>
      ))}
      <Sequence from={line2} layout="none"><Audio src={staticFile('sfx/kick.wav')} volume={0.7} /></Sequence>
      <Sequence from={flip - 6} layout="none"><Audio src={staticFile('sfx/whoosh.wav')} /></Sequence>
      <Sequence from={cardAt} layout="none"><Audio src={staticFile('sfx/pop.wav')} /></Sequence>
    </AbsoluteFill>
  );
};
