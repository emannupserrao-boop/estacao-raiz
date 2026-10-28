"""Original blaster-family sounds; only math and seeded noise, no recordings."""
import math, random, struct, wave, json, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parent
RATE=44100
report={'authoring':'Original FM and additive synthesis with deterministic noise; no film/game recordings or downloaded samples','sample_rate':RATE,'format':'mono PCM16','variants':[]}
for lane in range(2):
    for variant in range(3):
        rng=random.Random(4061+lane*100+variant)
        duration=.205 if lane==0 else .255
        start=(2100 if lane==0 else 1450)*(1+(variant-1)*.018)
        end=280 if lane==0 else 165
        sweep=.021 if lane==0 else .029
        phase=0.0
        values=[]
        old_noise=0.0
        for i in range(round(duration*RATE)):
            t=i/RATE
            u=t/duration
            freq=end+(start-end)*math.exp(-t/sweep)
            phase+=math.tau*freq/RATE
            # Bright inharmonic attack turns into a rounded energy body.
            fm_index=(2.6 if lane==0 else 1.9)*math.exp(-t/.028)
            carrier=math.sin(phase+fm_index*math.sin(phase*(1.71+variant*.025)))
            metal=.42*math.sin(phase*2.73)*math.exp(-t/.012)+.19*math.sin(phase*4.17)*math.exp(-t/.008)
            body=.32*math.sin(phase*.51)*math.exp(-t/.070)
            noise=rng.uniform(-1,1)
            transient=(noise-old_noise)*.14*math.exp(-t/.006)
            old_noise=noise
            envelope=min(1,t/.0015)*math.exp(-t/(.052 if lane==0 else .068))*(1-u)**.8
            signal=math.tanh((carrier+metal+body+transient)*1.15)*envelope
            # Very short dispersive echo, entirely synthesized.
            delay=round((.019 if lane==0 else .024)*RATE)
            if i>=delay: signal+=values[i-delay]*.10*(1-u)
            values.append(signal)
        peak=max(abs(v) for v in values)
        pcm=[round(v/peak*.22*32767) for v in values]
        path=ROOT/f'blaster_{"a" if lane==0 else "b"}_{variant}.wav'
        with wave.open(str(path),'wb') as f:
            f.setparams((1,2,RATE,0,'NONE','not compressed'))
            f.writeframes(struct.pack('<'+'h'*len(pcm),*pcm))
        report['variants'].append({'file':path.name,'defense':'A' if lane==0 else 'B','variant':variant,'seconds':duration,'start_hz':start,'end_hz':end,'sweep_seconds':sweep,'peak_pcm16':max(abs(v) for v in pcm),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(ROOT/'BLASTER-PROVENIENCIA.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
