import {interpolate, useCurrentFrame} from 'remotion';
import {clamp, display, out} from './theme';

// Kinetic headline: each word pops in at its own frame. `slam` makes words
// land from very large and blurred, for impact moments.
export const Words = ({words, color, size = 150, accent, slam = false, center = false}: {words: [string, number][]; color: string; size?: number; accent?: {word: string; color: string}; slam?: boolean; center?: boolean}) => {
  const frame = useCurrentFrame();
  const shadow = color === '#FFFFFF' ? '0 10px 40px rgba(0,0,0,0.35)' : '0 10px 30px rgba(36,42,94,0.15)';
  return (
    <div style={{fontFamily: display, fontWeight: 700, fontSize: size, lineHeight: 1.02, letterSpacing: -size * 0.03, color, display: 'flex', flexWrap: 'wrap', columnGap: size * 0.26, justifyContent: center ? 'center' : undefined}}>
      {words.map(([w, at]) =>
        w === '\n' ? (
          <div key={at} style={{flexBasis: '100%', height: 0}} />
        ) : (
          <span
            key={w + at}
            style={{
              display: 'inline-block',
              color: accent?.word === w ? accent.color : undefined,
              textShadow: accent?.word === w ? `0 0 40px ${accent.color}88, ${shadow}` : shadow,
              opacity: interpolate(frame, [at, at + (slam ? 2 : 3)], [0, 1], clamp),
              translate: slam ? undefined : interpolate(frame, [at, at + 6], ['0px 40px', '0px 0px'], {...clamp, easing: out}),
              scale: interpolate(frame, [at, at + (slam ? 5 : 6)], [slam ? 2.6 : 1.25, 1], {...clamp, easing: out}),
              filter: slam ? `blur(${interpolate(frame, [at, at + 5], [14, 0], clamp)}px)` : undefined,
            }}
          >
            {w}
          </span>
        ),
      )}
    </div>
  );
};
