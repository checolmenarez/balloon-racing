"""Original 'A toda vela' Home theme: 156 BPM, G major, 32 bars.

Deterministic offline synthesis using only Python's standard library.
No samples, recordings, external melodies or runtime dependencies.
Run: python tools/generate_home_music.py
"""
from array import array
from functools import lru_cache
from pathlib import Path
import math
import random
import sys
import wave

RATE = 44100
BPM = 156
BEAT = 60 / BPM
FRAMES = round(128 * BEAT * RATE)
left = array('f', [0]) * FRAMES
right = array('f', [0]) * FRAMES


@lru_cache(maxsize=512)
def tone(pitch, beats, voice):
    frequency = 440 * 2 ** ((pitch - 69) / 12)
    sustain = beats * BEAT
    release = .10 if voice == 'brass' else .065
    duration = sustain + release
    result = array('f')
    for i in range(round(duration * RATE)):
        t = i / RATE
        p = math.tau * frequency * t
        attack = min(1, t / (.008 if voice != 'brass' else .018))
        tail = max(0, min(1, (duration - t) / release)) ** 2
        if voice == 'bass':
            value = math.sin(p) + .28 * math.sin(2*p) + .10 * math.sin(3*p)
            envelope = math.exp(-t * 4)
        elif voice == 'brass':
            # Rounded, bright reed/brass: harmonics bloom, then soften.
            bright = math.exp(-t * 4)
            vibrato = .016 * math.sin(math.tau * 5.5 * t) * min(1, t / .15)
            value = (math.sin(p + vibrato) + .36 * math.sin(2*p + vibrato)
                     + .19 * bright * math.sin(3*p) + .09 * bright * math.sin(4*p))
            envelope = .68 + .32 * math.exp(-t * 8)
        elif voice == 'mallet':
            value = math.sin(p + 1.4 * math.sin(p * 3) * math.exp(-t * 22))
            envelope = math.exp(-t * 9)
        elif voice == 'bell':
            value = math.sin(p) + .30 * math.sin(3*p) * math.exp(-t * 10)
            envelope = math.exp(-t * 5)
        else:  # Short offbeat chord stabs.
            value = math.sin(p) + .24 * math.sin(2*p) + .10 * math.sin(4*p)
            envelope = math.exp(-t * 12)
        result.append(value * attack * tail * envelope)
    return result


@lru_cache(maxsize=16)
def percussion(kind):
    rng = random.Random(816 + sum(map(ord, kind)))
    duration = {'kick': .24, 'snare': .19, 'hat': .055, 'open': .16, 'crash': .65}[kind]
    result = array('f')
    last = 0
    for i in range(round(duration * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        high = (noise - last) * .5
        last = noise
        if kind == 'kick':
            phase = math.tau * (49*t + 3.7 * (1-math.exp(-t*42)))
            value = math.sin(phase) * math.exp(-t*20) + high * .09 * math.exp(-t*100)
        elif kind == 'snare':
            value = (.65 * noise + .30 * math.sin(math.tau*185*t)) * math.exp(-t*21)
            # Tiny delayed noise bursts give the backbeat a handclap character.
            for delay in [.012, .024]:
                if t > delay:
                    value += .15 * high * math.exp(-(t-delay)*65)
        else:
            decay = {'hat': 65, 'open': 22, 'crash': 7}[kind]
            value = high * math.exp(-t * decay)
        result.append(value * min(1, t/.0015) * min(1, (duration-t)/.015))
    return result


def mix(sound, beat, gain, pan=0, echo=False):
    start = round(beat * BEAT * RATE)
    lg = gain * math.sqrt((1-pan)/2)
    rg = gain * math.sqrt((1+pan)/2)
    for i, sample in enumerate(sound):
        j = (start+i) % FRAMES
        left[j] += sample * lg
        right[j] += sample * rg
    if echo:
        # Wrap both delays into the beginning: reverb/echo never cuts at the seam.
        mix(sound, beat+.75, gain*.13, -pan)
        mix(sound, beat+1.5, gain*.05, pan)


def note(beat, pitch, duration, gain, voice='brass', pan=0):
    mix(tone(pitch, duration, voice), beat, gain, pan, voice in ('brass', 'bell'))


# One-bar call/response cells. Rests and long answers keep the hook singable.
hook = [
    [(0,79,.42),(.5,83,.42),(1,86,.65),(1.75,88,.2),(2,86,.7),(3,83,.65)],
    [(0,81,.65),(.75,78,.2),(1,81,.65),(2,86,1.25),(3.5,81,.3)],
    [(0,83,.42),(.5,86,.42),(1,88,.65),(2,86,.42),(2.5,83,.42),(3,79,.65)],
    [(0,81,.65),(1,79,.65),(2,76,.65),(3,79,.65)],
    [(0,79,.42),(.5,83,.42),(1,86,.65),(1.75,88,.2),(2,91,.7),(3,88,.65)],
    [(0,90,.65),(.75,86,.2),(1,81,.65),(2,86,.65),(3,84,.65)],
    [(0,83,.65),(1,81,.42),(1.5,79,.42),(2,76,.65),(3,79,.65)],
    [(0,81,.42),(.5,78,.42),(1,74,.65),(2,78,.42),(2.5,81,.42),(3,86,.65)],
]
chords = [(43,[67,71,74]), (38,[66,69,74]), (40,[67,71,76]), (36,[64,67,72])]

for bar in range(32):
    base = bar * 4
    bridge = 16 <= bar < 24
    root, chord = chords[([3,1,0,2][bar%4] if bridge else bar%4)]
    if bar == 31:
        root, chord = chords[1]  # Dominant turnaround resolves into opening G.
    full = bar >= 4 and not (16 <= bar < 18)
    # First-second signature with a light kick; arrangement fills out over 4 bars.
    for offset in ([0,2,2.75] if full else [0,2]):
        mix(percussion('kick'),base+offset,.42)
    if bar > 0:
        for offset in [1,3]:
            mix(percussion('snare'),base+offset,.27)
        for step in range(8):
            mix(percussion('open' if step == 7 and full else 'hat'),base+step*.5,
                .085 if step%2 else .045,.28)
    if bar in [4,12,24]:
        mix(percussion('crash'),base,.16,-.25)
    if bar%8 == 7:
        for offset in [3.25,3.5,3.75]:
            mix(percussion('snare'),base+offset,.12 + (offset-3)*.10)
    for offset, interval in [(0,0),(.75,12),(1.5,7),(2,0),(2.75,12),(3.5,7)]:
        note(base+offset,root+interval,.30,.27,'bass')
    if bar > 0:
        for offset in [.5,1.5,2.5,3.5]:
            for pitch in chord:
                note(base+offset,pitch,.20,.065,'chord',-.30)
    if full:
        for step in range(8):
            note(base+step*.5,chord[step%3]+12,.22,.065,'mallet',.45)
    if bridge:
        # Contrasting lower-register response, then climb back to the hook.
        phrase = [(0,chord[0]+12,.65),(1,chord[1]+12,.4),(1.5,chord[2]+12,.4),
                  (2.5,chord[1]+12,.4),(3,chord[0]+12,.65)]
    else:
        phrase = hook[bar%8]
    for offset,pitch,duration in phrase:
        note(base+offset,pitch,duration,.225 if not bridge else .18,'brass',-.07)
        if bar >= 24 or bar == 0:
            note(base+offset,pitch+12,min(duration,.40),.045,'bell',.3)
    if bar%4 == 3:
        for offset,pitch in [(3,74),(3.25,78),(3.5,81),(3.75,86)]:
            note(base+offset,pitch,.18,.065,'mallet',.5)

# Soft saturation glues transients; peak normalization retains headroom.
peak = max(max(abs(v) for v in left), max(abs(v) for v in right))
normalizer = .84 / math.tanh(peak * 1.1)
pcm = array('h')
energy = 0.0
for a,b in zip(left,right):
    for value in (a,b):
        value = math.tanh(value * 1.1) * normalizer
        energy += value * value
        pcm.append(round(value * 32767))
if sys.byteorder != 'little':
    pcm.byteswap()
target = Path(__file__).resolve().parents[1] / 'assets/audio/home_arcade.wav'
with wave.open(str(target),'wb') as out:
    out.setparams((2,2,RATE,FRAMES,'NONE','not compressed'))
    out.writeframes(pcm.tobytes())
print(f'{target.name}: {BPM} BPM, {FRAMES/RATE:.3f}s, stereo PCM16/{RATE}Hz')
print(f'Peak: {20*math.log10(.84):.2f} dBFS; RMS: {20*math.log10(math.sqrt(energy/(FRAMES*2))):.2f} dBFS')
print('Original synthesized composition; deterministic seed; no external samples.')
