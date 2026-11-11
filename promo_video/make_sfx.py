"""Synthesizes the promo's sound effects (original, royalty-free) into public/sfx/.
Run: python make_sfx.py   (standard library only)"""
import math, random, struct, wave

RATE = 44100
random.seed(7)

def save(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    with wave.open(f'public/sfx/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s / peak * 0.9 * 32767)) for s in samples))

def env(i, n, attack, release):
    t = i / RATE; d = n / RATE
    a = min(1, t / attack) if attack else 1
    r = min(1, (d - t) / release) if release else 1
    return max(0, a * r)

def whoosh(dur=0.35, lo=300, hi=4000):
    n = int(dur * RATE); out = []; y = 0; y2 = 0
    for i in range(n):
        p = i / n
        cutoff = lo + (hi - lo) * math.sin(math.pi * p)  # sweeps up then down
        a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
        y += a * (random.uniform(-1, 1) - y); y2 += a * (y - y2)
        out.append(y2 * math.sin(math.pi * p) ** 1.5)
    return out

def pop(dur=0.12, f0=900, f1=250):
    n = int(dur * RATE); ph = 0; out = []
    for i in range(n):
        f = f1 + (f0 - f1) * math.exp(-i / RATE * 40); ph += 2 * math.pi * f / RATE
        out.append(math.sin(ph) * env(i, n, 0.002, dur * 0.8))
    return out

def click(dur=0.03):
    n = int(dur * RATE)
    return [(random.uniform(-1, 1) * 0.5 + math.sin(2 * math.pi * 2200 * i / RATE)) * math.exp(-i / RATE * 250) for i in range(n)]

def ding(dur=1.2, f=1320):
    n = int(dur * RATE)
    parts = [(1, 1), (2.76, 0.4), (5.4, 0.15)]
    return [sum(a * math.sin(2 * math.pi * f * m * i / RATE) for m, a in parts) * math.exp(-i / RATE * 4) * env(i, n, 0.003, 0) for i in range(n)]

def boom(dur=1.0):
    n = int(dur * RATE); ph = 0; out = []
    for i in range(n):
        f = 45 + 120 * math.exp(-i / RATE * 18); ph += 2 * math.pi * f / RATE
        out.append(math.sin(ph) * math.exp(-i / RATE * 3.5) * env(i, n, 0.003, 0))
    return out

def kick(dur=0.25):
    n = int(dur * RATE); ph = 0; out = []
    for i in range(n):
        f = 50 + 150 * math.exp(-i / RATE * 30); ph += 2 * math.pi * f / RATE
        out.append(math.sin(ph) * math.exp(-i / RATE * 14))
    return out

def riser(dur=1.0):
    n = int(dur * RATE); out = []; y = 0; ph = 0
    for i in range(n):
        p = i / n; cutoff = 200 + 6000 * p ** 2
        a = 1 - math.exp(-2 * math.pi * cutoff / RATE); y += a * (random.uniform(-1, 1) - y)
        ph += 2 * math.pi * (200 + 800 * p ** 2) / RATE
        out.append((y * 0.8 + math.sin(ph) * 0.2) * p ** 2)
    return out

def hold_hum(dur=0.6):  # rising tone while the finger holds
    n = int(dur * RATE); ph = 0; out = []
    for i in range(n):
        p = i / n; ph += 2 * math.pi * (300 + 500 * p) / RATE
        out.append(math.sin(ph) * p * env(i, n, 0.01, 0.02))
    return out

def impact(dur=1.4):  # deep boom + noise crack, for the big hits
    n = int(dur * RATE); ph = 0; out = []; y = 0
    for i in range(n):
        t = i / RATE
        f = 38 + 160 * math.exp(-t * 22); ph += 2 * math.pi * f / RATE
        a = 1 - math.exp(-2 * math.pi * (6000 * math.exp(-t * 8) + 300) / RATE)
        y += a * (random.uniform(-1, 1) - y)
        out.append(math.sin(ph) * math.exp(-t * 2.8) + y * 0.7 * math.exp(-t * 14))
    return out

def shimmer(dur=0.9):  # rising sparkle for shines
    n = int(dur * RATE); out = []
    notes = [1568, 1976, 2349, 3136, 3951]
    for i in range(n):
        t = i / RATE; v = 0
        for k, f in enumerate(notes):
            t0 = k * 0.07
            if t >= t0:
                v += math.sin(2 * math.pi * f * (t - t0)) * math.exp(-(t - t0) * 7)
        out.append(v)
    return out

save('impact', impact()); save('riser_long', riser(2.4)); save('shimmer', shimmer())
save('whoosh', whoosh()); save('whoosh_long', whoosh(0.6, 200, 3000))
save('pop', pop()); save('click', click()); save('ding', ding())
save('boom', boom()); save('kick', kick()); save('riser', riser()); save('hold', hold_hum())
print('done')
