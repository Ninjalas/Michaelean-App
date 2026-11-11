import {loadFont} from '@remotion/fonts';
import {Easing, staticFile} from 'remotion';

// Same colors as lib/theme/app_theme.dart.
export const C = {
  navy: '#242A5E',
  red: '#B3242E',
  page: '#F4F5F9',
  ink: '#16171D',
  black: '#0E0F14',
  night: '#080A1E', // very dark navy, for the final app-name frame
  white: '#FFFFFF',
  muted: '#6B6E7A',
};

export const BEAT = 15; // frames per beat (120 BPM at 30 fps)

export const display = 'Inter Display';
export const body = 'Inter';
loadFont({family: display, url: staticFile('fonts/InterDisplay-Bold.ttf'), weight: '700'});
loadFont({family: display, url: staticFile('fonts/InterDisplay-SemiBold.ttf'), weight: '600'});
loadFont({family: body, url: staticFile('fonts/Inter-Medium.ttf'), weight: '500'});

// Snappy ease-out used for almost every move.
export const out = Easing.bezier(0.16, 1, 0.3, 1);
export const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// App screenshots are 1170×2532 (390×844 at 3×).
export const SHOT_W = 1170;
export const SHOT_H = 2532;
