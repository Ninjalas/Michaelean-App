import {Audio} from '@remotion/media';
import {AbsoluteFill, Easing, Img, interpolate, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {Background} from '../Background';
import {Burst, flash, punch, shake, Shockwave} from '../Effects';
import {BEAT, C, clamp, display, out} from '../theme';
import {Words} from '../Words';

const Sfx = ({at, name, volume = 1}: {at: number; name: string; volume?: number}) => (
  <Sequence from={at} layout="none"><Audio src={staticFile(`sfx/${name}.wav`)} volume={volume} /></Sequence>
);

const SLAMS = [6, 11, 16, 20, 24]; // each tagline word lands on a kick

// 38–41 s: the tagline from the app, alone under a spotlight.
export const TaglineCard = () => {
  const frame = useCurrentFrame();
  const last = SLAMS[SLAMS.length - 1];
  const sh = shake(frame, last, 12, 20);
  return (
    <AbsoluteFill style={{scale: String(punch(frame, SLAMS, 0.035) + frame * 0.0006), translate: `${sh.x}px ${sh.y}px`}}>
      <Background stops={[[0, C.black]]} rays={false} />
      <Shockwave at={last} x={960} y={560} size={520} color="rgba(255,90,100,0.8)" />
      <Burst at={last} x={960} y={560} count={30} reach={800} />

      <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
        <div style={{width: 1500, display: 'flex', justifyContent: 'center', textAlign: 'center'}}>
          <Words slam center color={C.white} size={165} words={[['Your', SLAMS[0]], ['campus,', SLAMS[1]], ['\n', 900], ['beyond', SLAMS[2]], ['the', SLAMS[3]], ['classroom.', SLAMS[4]]]} accent={{word: 'classroom.', color: '#FF5A64'}} />
        </div>
      </AbsoluteFill>

      <AbsoluteFill style={{background: '#fff', opacity: flash(frame, last, 0.45, 6)}} />
      <Sfx at={0} name="boom" volume={0.6} />
      {SLAMS.slice(0, -1).map((f) => <Sfx key={f} at={f} name="kick" volume={0.85} />)}
      <Sfx at={last} name="impact" />
      <Sfx at={last + 30} name="riser" volume={0.5} />
    </AbsoluteFill>
  );
};

const EMBLEM = {x: 960, y: 380}; // emblem center

// 41–45 s: the app name on its own: emblem drops in, "Michaelean" rises
// underneath, a silver gloss runs once through the letters.
export const NameCard = () => {
  const frame = useCurrentFrame();
  const rise = 12; // name rises in
  const gloss = 34; // silver gloss passes through the name
  const end = 102; // soft fade to black starts
  const sh = shake(frame, 0, 12, 22);
  const pulse = 0.55 + Math.sin(frame / 9) * 0.15;
  const glossP = interpolate(frame, [gloss, gloss + 18], [100, -20], clamp);
  return (
    <AbsoluteFill style={{scale: String(punch(frame, [0, rise], 0.035) + frame * 0.0005), translate: `${sh.x}px ${sh.y}px`}}>
      <Background stops={[[0, C.night]]} rays={false} />
      {/* Extra darkness at the edges, so the logo and name sit in a pool of light. */}
      <AbsoluteFill style={{background: 'radial-gradient(ellipse at 50% 50%, transparent 30%, rgba(0,0,0,0.65) 100%)'}} />
      <div style={{position: 'absolute', left: EMBLEM.x - 380, top: EMBLEM.y - 380, width: 760, height: 760, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.32) 0%, transparent 65%)', opacity: pulse}} />
      <Shockwave at={0} x={EMBLEM.x} y={EMBLEM.y} size={460} />
      <Shockwave at={4} x={EMBLEM.x} y={EMBLEM.y} size={460} color="rgba(255,90,100,0.8)" />
      <Burst at={0} x={EMBLEM.x} y={EMBLEM.y} count={46} reach={1000} dur={30} />

      <Img
        src={staticFile('SMCL_Emblem.png')}
        style={{
          position: 'absolute', height: 380, left: EMBLEM.x - 162, top: EMBLEM.y - 190,
          filter: 'drop-shadow(0 24px 50px rgba(0,0,0,0.5))',
          translate: `0px ${Math.sin(frame / 20) * 5}px`,
          scale: interpolate(frame, [0, 12], [3, 1], {...clamp, easing: Easing.spring({damping: 14}), output: 'perceptual-scale'}),
          opacity: interpolate(frame, [0, 2], [0, 1], clamp),
        }}
      />

      {/* The name rises out of a mask; its fill is silver with a gloss band that sweeps once. */}
      <div style={{position: 'absolute', left: 0, right: 0, top: 640, height: 260, overflow: 'hidden', display: 'flex', justifyContent: 'center'}}>
        <div
          style={{
            fontFamily: display, fontWeight: 700, fontSize: 210, letterSpacing: -6, lineHeight: 1.15,
            translate: `0px ${interpolate(frame, [rise, rise + 12], [260, 0], {...clamp, easing: out})}px`,
            background: 'linear-gradient(105deg, #FFFFFF 0%, #FFFFFF 40%, #B9BDC9 46%, #FFFFFF 50%, #B9BDC9 54%, #FFFFFF 60%, #FFFFFF 100%), linear-gradient(180deg, #FFFFFF 55%, #D9DCE4 100%)',
            backgroundSize: '300% 100%, 100% 100%',
            backgroundPosition: `${glossP}% 0, 0 0`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 14px 30px rgba(0,0,0,0.45)) drop-shadow(0 0 30px rgba(255,255,255,0.25))',
          }}
        >
          Michaelean
        </div>
      </div>

      <AbsoluteFill style={{background: '#fff', opacity: flash(frame, 0, 0.85, 8)}} />
      <AbsoluteFill style={{background: '#000', opacity: interpolate(frame, [end, 8 * BEAT], [0, 1], {...clamp, easing: Easing.inOut(Easing.quad)})}} />

      <Sfx at={0} name="impact" />
      <Sfx at={rise} name="whoosh_long" volume={0.7} />
      <Sfx at={gloss} name="shimmer" volume={0.55} />
    </AbsoluteFill>
  );
};
