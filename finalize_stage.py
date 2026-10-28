"""Close the local audit without converting elapsed calendar time into effort."""
from datetime import datetime, timezone
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent
now = datetime.now(timezone.utc)
iso = lambda value: datetime.fromisoformat(value.replace("Z", "+00:00"))
authorization = iso("2026-10-17T05:19:09Z")
first = iso("2026-10-17T05:19:43Z")
pause_start = iso("2026-10-17T05:34:56Z")
resume = iso("2026-10-17T05:36:29Z")
report = {
    "candidate": "Estação Raiz", "status": "local playable sample; automated QA passed",
    "project_path": str(ROOT),
    "authorization_reference": "Sentinel_8fda0245ed4081919a190db867135983",
    "authorization_utc": authorization.isoformat(),
    "audit_closed_utc": now.isoformat(),
    "additional_effective_cap_seconds": 7200,
    "observed_windows_including_waits": [
        {"start": first.isoformat(), "end": pause_start.isoformat(), "elapsed_seconds": 913},
        {"start": resume.isoformat(), "end": now.isoformat(), "elapsed_seconds": round((now-resume).total_seconds(), 1)},
    ],
    "known_disconnected_pause_seconds_excluded": 93,
    "known_image_generation_wait_seconds_within_first_window": 63.5,
    "other_passive_waits_exact": None,
    "effective_effort_exact_seconds": None,
    "effective_effort_continuously_measured": False,
    "whole_authorized_calendar_interval_upper_bound_seconds": round((now-authorization).total_seconds(), 1),
    "calendar_interval_is_not_actual_effort": True,
    "whole_interval_below_additional_cap": (now-authorization).total_seconds() < 7200,
    "prior_history_accounting_preserved_separately": True,
    "prior_23h56_calendar_figure_not_reused_as_effort": True,
    "world_reconciliation": {
        "absent_on_initial_resume_inspection": True,
        "recreated_only_after_inspection": True,
        "import_runtime_and_gameplay_verified": True,
        "legacy_resume_record_world_missing_false_is_post_recreation_state": True,
    },
    "preservation": {
        "original_project": "defesa-potencia", "original_files_checked": 816,
        "original_files_modified": 0,
        "original_backup": "defesa-potencia-backup-20261017-raiz-start",
        "local_backup_files_hash_matched": 8,
        "partial_art_recovery_backup": "estacao-raiz-backup-art-20261017-0536",
        "partial_art_backup_is_not_certified_playable": True,
        "candidate_default_player_save_exists": (ROOT / "local/save.json").exists(),
    },
    "tests": {
        "base": {"checks": 45, "failures": 0},
        "extended": {"checks": 83, "failures": 0},
        "candidate_integrated": {"checks": 60, "failures": 0, "both_upgrade_branches_won": True},
        "audio": {"checks": 38, "failures": 0},
        "recording": {"checks_per_run": 17, "runs": ["normal", "slow", "native960"], "failures": 0},
        "objective_media": {"checks": 8, "failures": 0},
        "separate_process_game_checkpoint_reopen": True,
        "separate_process_audio_settings_reopen": True,
        "final_normal_main_launch_completed": True,
        "engine": "Godot 4.7.2 stable Compatibility/OpenGL 3.3",
        "nonfatal_shader_cache_warning": True,
        "human_playtest": False, "human_audio_listening": False,
    },
    "media": {
        "normal": "evidence/estacao-raiz-normal.mp4",
        "slow": "evidence/estacao-raiz-lento.mp4",
        "small_native_silent": "evidence/estacao-raiz-960.mp4",
        "earned_progression": "evidence/progressao-estufa.png",
        "source": "actual Godot viewport/mixer; automated fixtures",
        "normal_slow_offline_rendering": True,
        "slow_time_scale": 0.25,
        "slow_same_video_timed_inputs_cover_less_simulation_time": True,
    },
    "provenance": "assets/PROVENIENCIA.json",
    "installs_spending_publication_security_changes": 0,
    "new_file_uploads": 0,
    "local_delivery_blockers": [],
    "old_library_upload_block": {
        "scope": "four previously authorized VFX files, separate from this candidate",
        "result": "Library prepare_uploads is not available",
        "transferred_or_confirmed_ids": False,
        "retried_in_this_stage": False,
    },
    "remaining": ["human playtest and perceptual audio/art acceptance", "prototype scope only, three waves"],
}
assert report["whole_interval_below_additional_cap"]
assert not report["preservation"]["candidate_default_player_save_exists"]
(ROOT / "evidence/stage-final.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"audit_closed_utc": report["audit_closed_utc"], "calendar_upper_bound_seconds": report["whole_authorized_calendar_interval_upper_bound_seconds"], "effective_exact": False, "within_additional_cap": True}))
