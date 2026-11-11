import {Composition} from 'remotion';
import {Promo} from './Promo';

export const RemotionRoot = () => (
  <>
    {/* 1920×1080 for TV. 30 fps; one beat at 120 BPM = 15 frames. */}
    <Composition id="Promo" component={Promo} durationInFrames={1500} fps={30} width={1920} height={1080} />
  </>
);
