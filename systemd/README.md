# systemd user units

`deploy.sh` does not manage these (symlinking the whole `~/.config/systemd`
directory would hijack units it doesn't own). Link them individually:

```bash
ln -sf ~/dotfiles/systemd/user/repo-check.service ~/.config/systemd/user/
ln -sf ~/dotfiles/systemd/user/repo-check.timer   ~/.config/systemd/user/
systemctl --user daemon-reload
```

This repo only provides the unit files; *enablement* is declared per host in
`~/arch-config/services.txt` and applied with `archcfg enable`. (Enabling by
hand with `systemctl --user enable --now repo-check.timer` also works — then
capture it with `archcfg services`.)

## repo-check

`repo-check.timer` runs `repo-check fetch` daily (the tool is from
`~/git/repo-check`, installed separately) to refresh remote-tracking data and
rewrite `report.json`. The timer does **not** touch the desktop.

The polybar number is decoupled from the timer: `bin/repo-check-alert` derives
the alert from `report.json`, and `home/config/polybar/scripts/alerts.sh` calls
it on every refresh (~10s). So the count tracks the latest report — whether it
was written by the timed `fetch`, a manual `repo-check run`, or the menu's
re-check actions — and clears itself when all repos go clean. The menu side
(`bin/repo-check-{menu,popup}`) reads the same `report.json`.
