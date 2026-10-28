"""Make a local, restart-safe checkpoint from existing captures; no engine launch."""
from datetime import datetime, timezone
from pathlib import Path
import hashlib, json, shutil, zipfile
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
EV=ROOT/'evidence/polimento-20261017-0935'
CLONE=ROOT.parent/'estacao-raiz-qa-polimento-20261017-0935'
digest=lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
baseline=json.loads((EV/'baseline.json').read_text(encoding='utf-8'))
changed=[v['relative'] for v in baseline['source_manifest'] if not (ROOT/v['relative']).exists() or digest(ROOT/v['relative'])!=v['sha256']]
save_changes=[v for v in changed if v.startswith('local/')]
assert not save_changes
assert sorted(v for v in changed if v.endswith('.gd'))==sorted(['visual/actor.gd','visual/tower.gd','visual/world.gd','visual/impact_layer.gd'])

for source,name in [(CLONE/'evidence/qa-report.json','regression-base.json'),(CLONE/'evidence/raiz-qa-report.json','regression-integrated.json'),(CLONE/'evidence/polish/qa-report.json','regression-extended.json'),(CLONE/'evidence/raiz-reopen-report.json','regression-reopen.json'),(CLONE/'evidence/polish/depois-960x608.png','after-native-960.png')]:
    shutil.copy2(source,EV/name)
for name in ['regression-base.json','regression-integrated.json','regression-extended.json']:
    assert not json.loads((EV/name).read_text(encoding='utf-8')).get('failures')

before=json.loads((EV/'before/report.json').read_text())
after=json.loads((EV/'after/report.json').read_text())
assert not before['failures'] and not after['failures']
assert before['state']==after['state']
pause_a=Image.open(EV/'after/frame_0040.png').convert('RGB')
pause_b=Image.open(EV/'after/frame_0048.png').convert('RGB')
paused_pixels_equal=ImageChops.difference(pause_a,pause_b).getbbox() is None
assert paused_pixels_equal
assert Image.open(EV/'after-native-960.png').size==(960,608)

font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',22)
sheet=Image.new('RGB',(1200,820),(17,28,22))
for column,tag in enumerate(['before','after']):
    x=column*600
    img=Image.open(EV/tag/'frame_0002.png').convert('RGB')
    sheet.paste(img.resize((600,380),Image.Resampling.LANCZOS),(x,32))
    detail=Image.open(EV/tag/'frame_0014.png').convert('RGB').crop((430,95,820,465))
    sheet.paste(detail,(x+105,445))
    draw=ImageDraw.Draw(sheet)
    draw.text((x+12,3),'ANTES' if tag=='before' else 'DEPOIS / recuo, passada e impactos',font=font,fill=(247,226,187))
    draw.text((x+12,416),'Detalhe nativo / mesmo quadro da simulação',font=font,fill=(247,226,187))
sheet.save(EV/'comparativo-polimento.png')

film=Image.new('RGB',(1560,812),(17,28,22))
draw=ImageDraw.Draw(film)
for row,tag in enumerate(['before','after']):
    for column,frame in enumerate([0,2,8,14]):
        x,y=column*390,row*406
        crop=Image.open(EV/tag/('frame_%04d.png'%frame)).convert('RGB').crop((430,95,820,465))
        film.paste(crop,(x,y+33))
        draw.text((x+8,y+3),f'{"ANTES" if tag=="before" else "DEPOIS"} / quadro {frame}',font=font,fill=(247,226,187))
film.save(EV/'fases-articulacao.png')

old_manifest=json.loads((ROOT/'evidence/original-prototype-manifest.json').read_text(encoding='utf-8-sig'))
old_changed=[v['Path'] for v in old_manifest if not Path(v['Path']).is_file() or digest(Path(v['Path'])).upper()!=v['Hash']]
assert not old_changed
now=datetime.now(timezone.utc)
start=datetime.fromisoformat(baseline['start_observed_utc'].replace('Z','+00:00'))
report={
    'round':'Estação Raiz / polimento de efeitos e animação',
    'start_observed_utc':start.isoformat(),'checkpoint_utc':now.isoformat(),
    'separate_effective_cap_seconds':2700,
    'observed_calendar_upper_bound_seconds':round((now-start).total_seconds(),1),
    'effective_exact_seconds':None,'calendar_includes_waits_not_actual_effort':True,
    'prior_budgets_not_renewed_or_recalculated':True,
    'backup':baseline['backup'],'backup_files_hash_verified':baseline['files_hash_verified'],
    'baseline_save_files_preserved':len(baseline['save_files']),'save_files_changed':save_changes,
    'candidate_changed_existing_files':changed,
    'original_project_files_checked':len(old_manifest),'original_project_files_changed':old_changed,
    'rules_economy_controller_hud_audio_assets_unchanged':True,
    'regressions':{'base':45,'integrated':60,'extended':83,'checkpoint_separate_process_reopen':True,'before_capture':107,'after_capture':109,'failures':0},
    'matched_capture_gameplay_end_states_equal':True,
    'pause_pixels_identical_full_viewport':paused_pixels_equal,
    'native_resolutions':[[1200,760],[960,608]],
    'native_960_source':'isolated extended QA viewport capture',
    'performance':'short sample 60 FPS; processing median 5.016ms, p95 5.556ms; not general benchmark',
    'human_playtest_or_artistic_acceptance':False,
    'new_assets_or_installs_or_expenses_or_uploads':0,
    'interruption':{
        'reason':'parent requested safe checkpoint before Windows Sandbox setup/restart',
        'restart_performed':False,
        'long_new_tests_started_after_request':False,
        'earlier_capture_chain':'stale command terminated only after no Godot process and unchanged frame timestamps confirmed; subsequent single after capture completed with 109 checks',
        'earlier_failed_import':'stride type inference corrected before successful runtime regressions',
        'pending_small_slow_capture_chain':'did not reach these commands; not claimed as completed',
    },
    'remaining':['optional new slow/960 motion videos were not recorded before checkpoint','human evaluation of effect readability and movement'],
    'nonfatal_environment_warning':'user:// shader cache/profiler unavailable; security permissions unchanged',
}
assert report['observed_calendar_upper_bound_seconds']<2700
tmp=EV/'checkpoint.json.tmp'; tmp.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8'); tmp.replace(EV/'checkpoint.json')
print(json.dumps({'checkpoint_utc':report['checkpoint_utc'],'elapsed_upper_bound_seconds':report['observed_calendar_upper_bound_seconds'],'changed_existing':changed,'saves_preserved':len(baseline['save_files']),'original_unchanged':len(old_manifest),'paused_pixels_equal':paused_pixels_equal}))
