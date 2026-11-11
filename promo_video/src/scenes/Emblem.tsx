import {Audio} from '@remotion/media';
import {AbsoluteFill, Easing, Img, interpolate, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {Background, pick} from '../Background';
import {Burst, punch, Rays, Shockwave} from '../Effects';
import {BEAT, body, C, clamp, display, out} from '../theme';

// 3–6 s: the SMCL emblem lands, then the Michaelean wordmark (rebuilt from the app's own intro).
export const Emblem = () => {
  const frame = useCurrentFrame();
  const slide = 26; // emblem moves aside for the name
  const toNavy = 4 * BEAT; // background flips on the beat
  const onNavy = frame >= toNavy;
  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', scale: String(punch(frame, [0, toNavy], 0.04) + frame * 0.0005)}}>
      <Background stops={[[0, C.white], [toNavy, C.navy]]} rays={false} />
      <Rays x={onNavy ? '22%' : '50%'} y="49%" color={onNavy ? 'rgba(255,255,255,0.10)' : 'rgba(36,42,94,0.06)'} speed={0.6} opacity={interpolate(frame, [0, 6], [0, 1], clamp)} />
      <Shockwave at={2} x={960} y={540} color="rgba(36,42,94,0.5)" size={420} />
      <Shockwave at={toNavy} x={430} y={530} size={420} />
      <Burst at={toNavy} x={430} y={530} count={34} />

      {/* Starts shifted right by half the name's width, so the emblem alone is centered. */}
      <div style={{display: 'flex', alignItems: 'center', translate: `${interpolate(frame, [slide, slide + 14], [570, 0], {...clamp, easing: out})}px ${Math.sin(frame / 18) * 6}px`}}>
        <Img
          src={staticFile('SMCL_Emblem.png')}
          style={{
            height: 420,
            filter: `drop-shadow(0 20px 40px rgba(0,0,0,${onNavy ? 0.45 : 0.18}))`,
            scale: interpolate(frame, [0, 12, toNavy, toNavy + 6], [0.2, 1, 1.08, 1], {...clamp, easing: Easing.spring({damping: 12}), output: 'perceptual-scale'}),
            rotate: `${interpolate(frame, [0, 12], [-14, 0], {...clamp, easing: out})}deg`,
            opacity: interpolate(frame, [0, 3], [0, 1], clamp),
          }}
        />
        <div style={{position: 'relative', marginLeft: 60, clipPath: `inset(-20px ${interpolate(frame, [slide + 2, slide + 16], [100, 0], {...clamp, easing: out})}% -20px 0)`}}>
          <div style={{fontFamily: display, fontWeight: 700, fontSize: 200, letterSpacing: -6, color: pick(frame, [[0, C.navy], [toNavy, C.white]]), whiteSpace: 'nowrap', lineHeight: 1, textShadow: onNavy ? '0 0 50px rgba(255,255,255,0.25), 0 14px 40px rgba(0,0,0,0.35)' : '0 12px 30px rgba(36,42,94,0.18)'}}>Michaelean</div>
          <div
            style={{
              fontFamily: body, fontWeight: 500, fontSize: 44, marginTop: 18, whiteSpace: 'nowrap',
              color: pick(frame, [[0, C.muted], [toNavy, 'rgba(255,255,255,0.8)']]),
              opacity: interpolate(frame, [slide + 14, slide + 20], [0, 1], clamp),
              translate: interpolate(frame, [slide + 14, slide + 22], ['0px 20px', '0px 0px'], {...clamp, easing: out}),
            }}
          >
            Saint Michael’s College of Laguna
          </div>
        </div>
      </div>
      <Sequence from={0} layout="none"><Audio src={staticFile('sfx/impact.wav')} volume={0.9} /></Sequence>
      <Sequence from={slide - 2} layout="none"><Audio src={staticFile('sfx/whoosh_long.wav')} volume={0.7} /></Sequence>
      <Sequence from={toNavy} layout="none"><Audio src={staticFile('sfx/kick.wav')} volume={0.9} /></Sequence>
    </AbsoluteFill>
  );
};
