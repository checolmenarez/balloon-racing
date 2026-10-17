"""Render the original Balloon Racing loop using only Python's standard library.

Run from the repository root: python tools/generate_music.py
No samples, external recordings or runtime synthesis dependencies.
"""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

RATE = 32000
RACING = "--race" in sys.argv
BEAT = 60 / (152 if RACING else 112)
LENGTH = round(64 * BEAT * RATE)  # 16 bars, seamless wrap including release tails.
left = array('f', [0]) * LENGTH
right = array('f', [0]) * LENGTH
rng = random.Random(41)


def note(beat, midi, beats, gain, pan=0, voice='bell'):
    freq = 440 * 2 ** ((midi - 69) / 12)
    duration = beats * BEAT
    start = round(beat * BEAT * RATE)
    count = round(duration * RATE)
    for i in range(count):
        t = i / RATE
        phase = math.tau * freq * t
        attack = min(1, t / .012)
        release = min(1, (duration - t) / .08)
        if voice == 'bass':
            value = math.sin(phase) + .18 * math.sin(phase * 2)
            env = attack * release * math.exp(-t * 2)
        elif voice == 'lead':
            value = math.sin(phase) + .32 * math.sin(phase * 2) + .16 * math.sin(phase * 3)
            env = attack * release * math.exp(-t * 2.6)
        else:
            value = math.sin(phase) + .22 * math.sin(phase * 2) + .08 * math.sin(phase * 3)
            env = attack * release * math.exp(-t * 3.8)
        value *= env * gain
        j = (start + i) % LENGTH
        left[j] += value * (1 - pan) * .5
        right[j] += value * (1 + pan) * .5
        # A quiet, tempo-synchronised echo; wrap preserves the loop boundary.
        echo = (j + round(.75 * BEAT * RATE)) % LENGTH
        left[echo] += value * .10
        right[echo] += value * .14


def drum(beat, kind):
    start = round(beat * BEAT * RATE)
    duration = .22 if kind == 'kick' else .09
    for i in range(round(duration * RATE)):
        t = i / RATE
        fade = min(1, t / .002) * min(1, (duration - t) / .015)
        if kind == 'kick':
            value = math.sin(math.tau * (48*t + 6*(1-math.exp(-t*35)))) * math.exp(-t*22) * .24
        elif kind == 'snare':
            value = (rng.uniform(-1, 1) * .12 + math.sin(math.tau * 185 * t) * .08) * math.exp(-t * 30)
        else:
            value = rng.uniform(-1, 1) * math.exp(-t*65) * .035
        j = (start + i) % LENGTH
        left[j] += value * fade
        right[j] += value * fade


# C major / A minor / F major / G major; two melodic phrases with a reprise.
chords = [(48, [60, 64, 67, 71]), (45, [60, 64, 69, 72]),
          (41, [60, 65, 69, 72]), (43, [59, 62, 67, 74])]
melodies = [[76, 79, 81, 79, 76, 74], [72, 76, 79, 76, 74, 72],
            [77, 81, 84, 81, 79, 77], [74, 79, 77, 74, 71, 74],
            [79, 83, 84, 83, 79, 76], [81, 79, 76, 74, 72, 76],
            [77, 79, 81, 84, 81, 77], [79, 77, 74, 71, 74, 79]]
if RACING:
    # A brighter D-major chorus, moving bass, sixteenth-note fills and backbeat.
    chords = [(50, [62, 66, 69, 74]), (47, [62, 66, 71, 74]),
              (43, [62, 67, 71, 74]), (45, [61, 64, 69, 73])]
    melodies = [[78, 81, 83, 85, 83, 81, 78, 76],
                [78, 83, 86, 85, 83, 81, 78, 74],
                [79, 83, 86, 83, 81, 79, 78, 79],
                [81, 85, 88, 85, 83, 81, 76, 73],
                [86, 85, 81, 78, 81, 83, 85, 86],
                [83, 86, 90, 86, 85, 83, 81, 78],
                [79, 81, 83, 86, 83, 81, 79, 78],
                [81, 85, 83, 81, 76, 73, 76, 81]]
for bar in range(16):
    base = bar * 4
    root, chord = chords[(bar // 2) % 4]
    for step in range(8):
        note(base + step * .5, chord[step % 4], .65, .075, -.35 if step % 2 else .35)
    for beat in (0, 2):
        note(base + beat, root, 1.5, .24, voice='bass')
        drum(base + beat, 'kick')
    for beat in (.5, 1.5, 2.5, 3.5):
        drum(base + beat, 'hat')
    if RACING:
        for offset in (1, 3):
            drum(base + offset, 'snare')
        for offset in (1.5, 3.5):
            note(base + offset, root + 12, .4, .19, voice='bass')
        if bar % 4 == 3:
            for offset in (3, 3.25, 3.5, 3.75):
                drum(base + offset, 'hat')
        phrase = melodies[bar // 2]
        for step in range(4):
            note(base + (0, .75, 1.5, 2.5)[step], phrase[(bar % 2) * 4 + step], .7, .19, voice='lead')
    elif bar % 2 == 0:
        for offset, pitch in zip((0, 1, 1.5, 2.5, 3.5, 5), melodies[bar // 2]):
            note(base + offset, pitch, 1.25, .17, -.1)

peak = max(max(abs(v) for v in left), max(abs(v) for v in right))
pcm = array('h')
for a, b in zip(left, right):
    pcm.extend((round(a / peak * 26000), round(b / peak * 26000)))
if sys.byteorder != 'little':
    pcm.byteswap()
target = Path(__file__).resolve().parents[1] / ('assets/audio/carrera.wav' if RACING else 'assets/audio/valle_ventoso.wav')
target.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(target), 'wb') as out:
    out.setparams((2, 2, RATE, LENGTH, 'NONE', 'not compressed'))
    out.writeframes(pcm.tobytes())
print(f'{target.name}: {LENGTH / RATE:.2f}s, stereo PCM16, peak -2 dBFS')
