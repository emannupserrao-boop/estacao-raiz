"""Original crystal/metal SFX. Python stdlib only; no source recordings."""
import math, random, struct, wave, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RATE = 44100
random.seed(1647)
specs = {
    'shot': (.16, 880, 260, .22),
    'impact': (.20, 310, 130, .18),
    'transfer': (.65, 220, 990, .20),
    'ui': (.075, 740, 660, .14),
    'victory': (1.15, 523.25, 0, .25),
    'defeat': (1.05, 392, 0, .23),
}
report = {'authoring': 'Original deterministic mathematical synthesis; no sampled or downloaded audio', 'sample_rate': RATE, 'format': 'mono PCM16', 'files': {}}
for name, (duration, f0, f1, level) in specs.items():
    samples = []
    phase = 0.0
    for i in range(int(duration * RATE)):
        t = i / RATE
        u = t / duration
        if name in ('victory', 'defeat'):
            notes = [1, 1.25, 1.5, 2] if name == 'victory' else [1, .84, .667, .5]
            k = min(3, int(u * 4))
            freq = f0 * notes[k]
            env = min(1, (u * 4 - k) * 30) * math.exp(-3 * (u * 4 - k)) * (1-u)**.5
        else:
            freq = f0 + (f1-f0)*u
            env = min(1, t/.006) * (1-u)**(1.2 if name == 'transfer' else 2.8)
        phase += 2*math.pi*freq/RATE
        value = math.sin(phase) + .22*math.sin(phase*2.76)*math.exp(-8*t)
        if name == 'impact': value += random.uniform(-1,1)*.35*math.exp(-32*t)
        samples.append(value*env)
    peak = max(abs(v) for v in samples)
    pcm = [round(v/peak*level*32767) for v in samples]
    with wave.open(str(ROOT/(name+'.wav')), 'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(struct.pack('<'+'h'*len(pcm),*pcm))
    report['files'][name+'.wav'] = {'seconds':duration,'peak_pcm16':max(abs(v) for v in pcm),'level':level}
(ROOT/'PROVENIENCIA.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
