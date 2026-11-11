import {Audio} from '@remotion/media';
import {Sequence, staticFile} from 'remotion';
import {FeatureScene} from '../FeatureScene';
import {C} from '../theme';

// Each feature is 8 beats (120 frames). Tap, crop, and camera points are in
// screenshot pixels (390×844 app points × 3). Camera: start close on what
// matters, pull back on the beat, push in on the button that gets tapped,
// pull out again. Some zooms also keep small print out of the frame.

// 10–14 s: Home is "what's next for me today".
export const HomeScene = () => (
  <FeatureScene
    side="left"
    bg={[[0, C.page], [60, C.navy]]}
    captions={[
      {at: 4, text: 'Your day, / at a glance.', accent: 'glance.'},
      {at: 60, text: 'Campus news / in one feed.', accent: 'feed.'},
    ]}
    screens={[{src: 'home', at: 0}, {src: 'home_feed', at: 60, via: 'fade'}]}
    cam={[
      {at: 0, zoom: 1.8, x: 585, y: 1040}, // the Up next card
      {at: 15, zoom: 1},
      {at: 62, zoom: 1.7, x: 585, y: 1750}, // the announcements
    ]}
    pops={[{at: 26, until: 56, src: 'home', x: 60, y: 447, w: 1050, h: 257, scale: 1.9, to: {x: 470, y: 110}}]}
  />
);

// 14–18 s: find an event, Register, see who's going.
export const EventsScene = () => (
  <FeatureScene
    bg={[[0, C.black], [52, C.red], [80, C.navy]]}
    captions={[
      {at: 4, text: 'Find your / next event.', accent: 'event.'},
      {at: 52, text: 'Register / in one tap.', accent: 'tap.'},
      {at: 80, text: 'See who’s / going.', accent: 'going.'},
    ]}
    screens={[
      {src: 'events', at: 0, light: true},
      {src: 'event_ev1', at: 32, via: 'push', light: true},
      {src: 'event_ev1_after', at: 54, light: true},
    ]}
    taps={[{at: 28, x: 585, y: 897}, {at: 50, x: 225, y: 1668}]}
    cam={[
      {at: 0, zoom: 1.8, x: 585, y: 897}, // the event card
      {at: 14, zoom: 1},
      {at: 42, zoom: 1.9, x: 225, y: 1668}, // the Register button
      {at: 60, zoom: 1},
    ]}
    // The Going names fly out of the phone (just the names, not the note below them).
    pops={[{at: 84, src: 'going', x: 58, y: 306, w: 1052, h: 420, scale: 1.65, to: {x: 640, y: 745}}]}
  />
);

// 18–22 s: Connect, and privacy you control.
export const ConnectScene = () => (
  <FeatureScene
    side="left"
    bg={[[0, C.page], [54, C.navy], [84, C.black]]}
    captions={[
      {at: 4, text: 'Find your / people.', accent: 'people.'},
      {at: 54, text: 'Connect / in one tap.', accent: 'tap.'},
      {at: 84, text: 'You choose who / sees your events.', accent: 'events.', size: 118},
    ]}
    screens={[
      {src: 'people', at: 0, light: true},
      {src: 'person', at: 32, via: 'push', light: true},
      {src: 'person_after', at: 56, light: true},
      {src: 'privacy', at: 86, via: 'push', light: true},
    ]}
    taps={[{at: 28, x: 410, y: 576}, {at: 52, x: 585, y: 1323}]}
    cam={[
      {at: 0, zoom: 1.8, x: 410, y: 576}, // Isabel in suggestions
      {at: 14, zoom: 1},
      {at: 44, zoom: 1.9, x: 585, y: 1323}, // the Connect button
      {at: 62, zoom: 1},
      {at: 88, zoom: 1.9, x: 585, y: 500, ty: 560}, // the privacy choices
    ]}
  />
);

// 22–26 s: clubs: browse, request to join, club posts.
export const ClubsScene = () => (
  <FeatureScene
    bg={[[0, C.navy], [52, C.page], [82, C.red]]}
    captions={[
      {at: 4, text: 'Join a / club.', accent: 'club.'},
      {at: 52, text: 'Request / to join.', accent: 'join.'},
      {at: 82, text: 'Never miss / a club post.', accent: 'post.', size: 130},
    ]}
    screens={[
      {src: 'orgs', at: 0, light: true},
      {src: 'org6', at: 30, via: 'push', light: true},
      {src: 'org6_after', at: 52, light: true},
      {src: 'org1_news', at: 84, via: 'push', light: true},
    ]}
    taps={[{at: 26, x: 585, y: 1664}, {at: 48, x: 585, y: 1272}]}
    cam={[
      {at: 0, zoom: 1.8, x: 585, y: 1664}, // SMCL Robotics Club in the list
      {at: 14, zoom: 1},
      {at: 40, zoom: 1.9, x: 585, y: 1272}, // Request to Join
      {at: 58, zoom: 1},
      {at: 86, zoom: 1.7, x: 585, y: 700, ty: 520}, // the club header
    ]}
    // Just the post's time, URGENT tag and title.
    pops={[{at: 96, src: 'org1_news', x: 58, y: 1652, w: 1052, h: 313, scale: 1.7, to: {x: 620, y: 760}}]}
  />
);

// 26–30 s: three quick flashes, 40 frames each.
export const GradesFlash = () => (
  <FeatureScene
    bg={[[0, C.navy]]}
    captions={[{at: 2, text: 'Your GWA, / explained.', accent: 'explained.'}]}
    screens={[{src: 'grades', at: 0, light: true}, {src: 'grades_avg', at: 18, via: 'sheet', sheetTop: 0.143, light: true}]}
    cam={[{at: 0, zoom: 1.8, x: 585, y: 550, ty: 600}]} // the GWA card, table footer out of frame
  />
);

export const ClearanceFlash = () => (
  <FeatureScene
    side="left"
    bg={[[0, C.page]]}
    captions={[{at: 2, text: 'No more chasing / signatures.', accent: 'signatures.', size: 120}]}
    screens={[{src: 'clearance', at: 0, light: true}]}
    cam={[{at: 0, zoom: 1.7, x: 585, y: 1100}, {at: 10, zoom: 1}]}
    pops={[{at: 20, src: 'clearance', x: 58, y: 234, w: 1052, h: 483, scale: 1.6, to: {x: 560, y: 120}}]}
  />
);

export const BellFlash = () => (
  <FeatureScene
    bg={[[0, C.red]]}
    captions={[{at: 2, text: 'Never miss / a notice.', accent: 'notice.'}]}
    screens={[{src: 'home', at: 0}, {src: 'bell', at: 10, via: 'sheet', sheetTop: 0.144}]}
    cam={[{at: 0, zoom: 1}, {at: 14, zoom: 1.5, x: 585, y: 1100}]}
  />
);

// 30–34.5 s: fast swipes that keep speeding up, each one punching toward the
// camera; backgrounds cut every beat, then every half beat; at the end the
// phone flies into the camera.
const montage = ['home', 'life', 'events', 'event_ev1', 'orgs', 'people', 'person', 'clearance', 'home_feed', 'event_ev1_after', 'person_after', 'home', 'life', 'events'];
const navyTop = new Set(['home', 'life', 'home_feed']);
const gaps = [11, 10, 10, 9, 9, 8, 8, 7, 7, 6, 5, 5, 4]; // frames between swipes, shrinking
const swipeAt = gaps.reduce((acc, g) => [...acc, acc[acc.length - 1] + g], [0]);
export const Montage = () => (
  <FeatureScene
    bg={[[0, C.navy], [15, C.red], [30, C.black], [45, C.page], [60, C.navy], [75, C.red], [90, C.black], [98, C.navy], [105, C.red], [113, C.black], [120, C.navy], [128, C.red]]}
    captions={[
      {at: 4, text: 'Everything / on campus.', accent: 'campus.'},
      {at: 68, text: 'All in / one app.', accent: 'app.'},
    ]}
    screens={montage.map((src, i) => ({src, at: swipeAt[i], via: i ? 'push' : undefined, light: !navyTop.has(src)}))}
    depthPulse
    flyOut={125}
  />
);

// 34.5–38 s: one closing beat for the teacher side, ending in a riser and
// strobing cuts that lead into the end.
export const TeachersBeat = () => (
  <>
    <FeatureScene
      side="left"
      bg={[[0, C.navy], [45, C.black], [75, C.red], [90, C.black], [94, C.navy], [98, C.red], [101, C.black]]}
      captions={[{at: 4, text: '…and your teachers / are on it too.', accent: 'too.', size: 120}]}
      screens={[
        {src: 't_home', at: 0},
        {src: 't_life', at: 30, via: 'push'},
        {src: 't_club', at: 62, via: 'push', light: true},
      ]}
      cam={[
        {at: 0, zoom: 1},
        {at: 32, zoom: 1.6, x: 585, y: 1100}, // classes with Start attendance
        {at: 52, zoom: 1.8, x: 585, y: 1550, ty: 560}, // framed low before the club page slides in, so only its member list shows
      ]}
    />
    <Sequence from={30} layout="none"><Audio src={staticFile('sfx/riser_long.wav')} volume={0.7} /></Sequence>
  </>
);
