"""Original arcade effects. Run with Python's standard library; no samples."""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

RATE = 32000
TARGET = Path(__file__).resolve().parents[1] / 'assets/audio'
TARGET.mkdir(parents=True, exist_ok=True)
for name, duration in [('collision', .22), ('turbo', .85), ('explosion', .65)]:
    rng = random.Random(73)
    samples = []
    low = 0.0
    for i in range(round(RATE * duration)):
        t = i / RATE
        u = t / duration
        noise = rng.uniform(-1, 1)
        low += .12 * (noise - low)
        edge = min(1, t / .004) * min(1, (duration-t) / .04)
        if name == 'collision':
            value = (math.sin(math.tau * (160*t - 180*t*t)) * .7 + noise * .2) * math.exp(-t*20)
        elif name == 'turbo':
            phase = math.tau * (220*t + 500*t*t)
            value = (math.sin(phase) * .32 + math.sin(phase*1.5) * .12 + low * .8) * math.sin(math.pi*u)**.7
        else:
            value = (low * 2 + math.sin(math.tau * (65*t - 28*t*t)) * .4 + noise * .16) * math.exp(-t*7)
        samples.append(value * edge)
    peak = max(abs(x) for x in samples)
    pcm = array('h', (round(x / peak * 24000) for x in samples))
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(TARGET / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, RATE, len(samples), 'NONE', 'not compressed'))
        out.writeframes(pcm.tobytes())
    print(name, duration, 'seconds')
