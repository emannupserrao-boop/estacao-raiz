import array,json,math,wave
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]/'evidence'/'blaster'
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',24)
for file,label in [('before-label.png','ANTES - pulso original'),('after-label.png','DEPOIS - blasters A / B')]:
    image=Image.new('RGBA',(330,44),(10,20,15,235))
    ImageDraw.Draw(image).text((12,4),label,font=font,fill=(245,240,220))
    image.save(root/file)
def inspect(file):
    with wave.open(str(root/file),'rb') as f:
        rate,channels=f.getframerate(),f.getnchannels()
        samples=array.array('h',f.readframes(f.getnframes()))
    return samples,rate,channels
data,rate,channels=inspect('mix.wav')
stress,_,_=inspect('stress.wav')
def window(a,b):
    s=data[round(a*rate)*channels:round(b*rate)*channels]
    return {'peak':max(abs(v) for v in s),'rms':round(math.sqrt(sum(v*v for v in s)/len(s)),3)}
report={'sample_rate':rate,'channels':channels,'peak':max(abs(v) for v in data),'clipped_samples':sum(abs(v)>=32767 for v in data),'stress_peak':max(abs(v) for v in stress),'stress_clipped_samples':sum(abs(v)>=32767 for v in stress),'paused':window(3.55,4.15),'muted':window(5.55,6.15),'combat':window(.6,3.1),'human_listening':False,'comparative':'matched engine fixtures and 65% volume, original audio at 0-3s; new mix at 3-6s; no normalization'}
report['passed']=report['clipped_samples']==0 and report['stress_clipped_samples']==0 and report['paused']['peak']==0 and report['muted']['peak']==0 and report['combat']['peak']>100
(root/'mix-analysis.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
raise SystemExit(0 if report['passed'] else 1)
