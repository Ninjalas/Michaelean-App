import {AbsoluteFill, Sequence, useCurrentFrame} from 'remotion';
import {flash} from './Effects';
import {NameCard, TaglineCard} from './scenes/EndCard';
import {Emblem} from './scenes/Emblem';
import {BellFlash, ClearanceFlash, ClubsScene, ConnectScene, EventsScene, GradesFlash, HomeScene, Montage, TeachersBeat} from './scenes/Features';
import {Hook} from './scenes/Hook';
import {QrScene} from './scenes/QrScene';
import {BEAT} from './theme';

// 50 s = 100 beats at 120 BPM; every cut lands on a beat. The hook is 16 beats
// (the question gets time to land); everything after starts at beat 16.
const H = 16 * BEAT;
const CUTS = [0, 6, 14, 22, 30, 38, 46].map((b) => H + b * BEAT).concat([H + 46 * BEAT + 40, H + 46 * BEAT + 80, H + 54 * BEAT, H + 63 * BEAT, H + 76 * BEAT]);

// A quick white flash on every scene change.
const FlashCuts = () => {
  const frame = useCurrentFrame();
  const o = CUTS.reduce((a, at) => a + flash(frame, at, 0.55, 5), 0);
  return <AbsoluteFill style={{background: '#fff', opacity: Math.min(o, 1), pointerEvents: 'none'}} />;
};

export const Promo = () => (
  <AbsoluteFill style={{background: '#000'}}>
    <Sequence name="Hook" durationInFrames={H}><Hook /></Sequence>
    <Sequence name="Emblem" from={H} durationInFrames={6 * BEAT}><Emblem /></Sequence>
    <Sequence name="Hold for QR" from={H + 6 * BEAT} durationInFrames={8 * BEAT}><QrScene /></Sequence>
    <Sequence name="Home" from={H + 14 * BEAT} durationInFrames={8 * BEAT}><HomeScene /></Sequence>
    <Sequence name="Events" from={H + 22 * BEAT} durationInFrames={8 * BEAT}><EventsScene /></Sequence>
    <Sequence name="Connect" from={H + 30 * BEAT} durationInFrames={8 * BEAT}><ConnectScene /></Sequence>
    <Sequence name="Clubs" from={H + 38 * BEAT} durationInFrames={8 * BEAT}><ClubsScene /></Sequence>
    <Sequence name="Grades" from={H + 46 * BEAT} durationInFrames={40}><GradesFlash /></Sequence>
    <Sequence name="Clearance" from={H + 46 * BEAT + 40} durationInFrames={40}><ClearanceFlash /></Sequence>
    <Sequence name="Bell" from={H + 46 * BEAT + 80} durationInFrames={40}><BellFlash /></Sequence>
    <Sequence name="Montage" from={H + 54 * BEAT} durationInFrames={9 * BEAT}><Montage /></Sequence>
    <Sequence name="Teachers" from={H + 63 * BEAT} durationInFrames={7 * BEAT}><TeachersBeat /></Sequence>
    <Sequence name="Tagline" from={H + 70 * BEAT} durationInFrames={6 * BEAT}><TaglineCard /></Sequence>
    <Sequence name="App name" from={H + 76 * BEAT} durationInFrames={8 * BEAT}><NameCard /></Sequence>
    <FlashCuts />
    {/* No background music: it's added in a separate edit. Sound effects only. */}
  </AbsoluteFill>
);
