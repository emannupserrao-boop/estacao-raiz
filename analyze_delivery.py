"""Validate captured output and compose QA contact sheets from actual pixels."""
import array,hashlib,json,math,wave
from pathlib import Path
from PIL import Image,ImageChops,ImageDraw,ImageFont
root=Path(__file__).resolve().parent
ev=root/'evidence'
with wave.open(str(ev/'audio/mix.wav'),'rb') as f:
    rate,channels=f.getframerate(),f.getnchannels()
    mix=array.array('h',f.readframes(f.getnframes()))
with wave.open(str(ev/'audio/stress.wav'),'rb') as f: stress=array.array('h',f.readframes(f.getnframes()))
def window(start,end):
    samples=mix[round(start*rate)*channels:round(end*rate)*channels]
    return {'peak':max(abs(v) for v in samples),'rms':round(math.sqrt(sum(v*v for v in samples)/len(samples)),3)}
report={'mix_peak':max(abs(v) for v in mix),'mix_clipped_samples':sum(abs(v)>=32767 for v in mix),'stress_peak':max(abs(v) for v in stress),'stress_clipped_samples':sum(abs(v)>=32767 for v in stress),'paused_window':window(3.1,3.7),'muted_window':window(6.1,6.7),'combat_window':window(1,2.5),'human_listening':False,'native_small_png_size':Image.open(ev/'motion/small-000.png').size}
paused_a=Image.open(ev/'motion/small-054.png').crop((0,110,960,490))
paused_b=Image.open(ev/'motion/small-068.png').crop((0,110,960,490))
report['paused_world_pixels_equal']=ImageChops.difference(paused_a,paused_b).getbbox() is None
old=json.loads((ev/'original-prototype-manifest.json').read_text(encoding='utf-8-sig'))
modified=[v['Path'] for v in old if not Path(v['Path']).is_file() or hashlib.sha256(Path(v['Path']).read_bytes()).hexdigest().upper()!=v['Hash']]
report['original_files_checked']=len(old); report['original_files_modified']=modified
report['candidate_player_save_exists']=(root/'local/save.json').exists()
report['checks']={'mix_no_clipping':report['mix_clipped_samples']==0,'stress_no_clipping':report['stress_clipped_samples']==0,'pause_silent':report['paused_window']['peak']==0,'mute_silent':report['muted_window']['peak']==0,'combat_contains_audio':report['combat_window']['peak']>100,'pause_pixels_equal':report['paused_world_pixels_equal'],'small_is_native_960x608':report['native_small_png_size']==(960,608),'original_prototype_unchanged':not modified}
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23)
image=Image.new('RGB',(1200,840),(18,30,23))
for i,(name,label) in enumerate([('final-overview.png','0 / Estufa adormecida'),('branch-1-sector-1.png','1 / Irrigação reativada'),('branch-1-sector-2.png','2 / Leitos com brotos'),('branch-1-sector-3.png','3 / Floração e coração desperto')]):
    x,y=i%2*600,i//2*420
    image.paste(Image.open(ev/name).convert('RGB').resize((600,380),Image.Resampling.LANCZOS),(x,y+36))
    ImageDraw.Draw(image).text((x+12,y+3),label,font=font,fill=(247,230,194))
image.save(ev/'progressao-estufa.png')
comparison=Image.new('RGB',(1200,1590),(18,30,23))
before=root.parent/'defesa-potencia/evidence/blaster/combate-com-som.png'
comparison.paste(Image.open(before).convert('RGB'),(0,34))
comparison.paste(Image.open(ev/'final-combat.png').convert('RGB'),(0,824))
draw=ImageDraw.Draw(comparison)
draw.text((18,2),'ANTES / Potência compartilhada',font=font,fill=(247,230,194))
draw.text((18,794),'CANDIDATO / Estação Raiz',font=font,fill=(247,230,194))
comparison.save(ev/'antes-depois-identidade.png')
film=Image.new('RGB',(1200,820),(18,30,23))
for i,frame in enumerate([0,1,5,14,54,110]):
    crop=Image.open(ev/f'motion/normal-{frame:03d}.png').crop((510,90,870,490)).resize((360,400),Image.Resampling.NEAREST)
    x,y=i%3*400,i//3*410
    film.paste(crop,(x+20,y+10))
film.save(ev/'motion-review.png')
(ev/'delivery-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
raise SystemExit(0 if all(report['checks'].values()) else 1)
