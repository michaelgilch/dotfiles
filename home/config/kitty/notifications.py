"""Mark the originating kitty window urgent when an app inside it notifies.

kitty auto-loads this file as its notification filter script (see 
filter_notification in kitty.conf(5)) and calls main() for every notification.

Returning True would suppress the popup. This hook never suppresses anything.
Instead, it exists for the side effect of setting the X11 urgency hint on the 
originating window so i3 flags its workspace urgent and polybar can highlight it 
via label-urgent.

No clear-logic is needed. i3 drops the urgency flag when the window gains focus,
and ignores urgency on the already-focused window, so the session you are 
actively watching never highlights its own workspace.

Requires xdotool.
"""

def main(cmd) -> bool:
    try:
        from kitty.fast_data_types import get_boss, x11_window_id

        window = get_boss().window_id_map.get(cmd.channel_id)
        
        # channel_id 0 is kitty itself (e.g. update notices): no window
        if window is not None:
            import subprocess
            subprocess.Popen(
                ['xdotool', 'set_window', '--urgency', '1',
                 str(x11_window_id(window.os_window_id))],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
    except Exception:
        pass  # attention-marking must never break notification delivery
    return False
