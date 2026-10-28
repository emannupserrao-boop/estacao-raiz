"""Inspect captured engine mix, including silent pause and mute windows."""
import array, json, math, wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'evidence'/'audio'
with wave.open(str(root/'mix-engine.wav'),'rb') as f:
    rate, channels = f.getframerate(), f.getnchannels()
    values=array.array('h',f.readframes(f.getnframes()))
def region(start,end):
    data=values[round(start*rate)*channels:round(end*rate)*channels]
    peak=max((abs(v) for v in data),default=0)
    rms=math.sqrt(sum(v*v for v in data)/max(1,len(data)))
    return {'start':start,'end':end,'peak_pcm16':peak,'rms_pcm16':round(rms,3),'nonzero_samples':sum(v!=0 for v in data)}
report={'sample_rate':rate,'channels':channels,'samples':len(values),'peak_pcm16':max(abs(v) for v in values),'clipped_samples':sum(abs(v)>=32767 for v in values),'windows':{},'human_listening':False}
# Eight setup frames precede frame zero; leave margin for audio-server buffers.
for name,a,b in [('combat',.6,3.1),('paused',3.55,4.15),('muted',5.55,6.15),('victory',8.6,9.5),('defeat',10.6,11.5)]:
    report['windows'][name]=region(a,b)
report['checks']={'nonempty_combat':report['windows']['combat']['peak_pcm16']>100,'pause_silent':report['windows']['paused']['peak_pcm16']==0,'mute_silent':report['windows']['muted']['peak_pcm16']==0,'victory_audible':report['windows']['victory']['peak_pcm16']>100,'defeat_audible':report['windows']['defeat']['peak_pcm16']>100,'no_pcm_clipping':report['clipped_samples']==0}
with wave.open(str(root/'stress.wav'),'rb') as f:
    stress=array.array('h',f.readframes(f.getnframes()))
report['stress']={'volume':1.0,'simultaneous_voices':6,'bursts':8,'peak_pcm16':max(abs(v) for v in stress),'clipped_samples':sum(abs(v)>=32767 for v in stress)}
report['checks']['stress_no_pcm_clipping']=report['stress']['clipped_samples']==0
(root/'mix-analysis.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
raise SystemExit(0 if all(report['checks'].values()) else 1)
