{local, ...}: {
  programs.niri.settings = {
    # Stylix's niri target sets border/focus-ring colors and the cursor, so we
    # only describe behaviour here.

    prefer-no-csd = true;

    input = {
      keyboard.xkb = {
        layout = "us";
        options = "grp:alt_shift_toggle"; # Alt+Shift switches
      };
      # Each window remembers its own layout ("global" = one shared layout).
      keyboard.track-layout = "window";
      touchpad = {
        tap = true;
        natural-scroll = false;
        dwt = true; # disable-while-typing
      };
      mouse = {
        accel-profile = "flat";
        natural-scroll = false; # match macOS-style scrolling (also set on touchpad)
      };
      focus-follows-mouse.enable = true;
    };

    # Matched by make/model/serial (local.nix) so a connector rename doesn't
    # drop the scale back to niri's guess.
    outputs.${local.monitor.name} = {
      scale = local.monitor.scale;
      mode = {
        width = local.monitor.width;
        height = local.monitor.height;
        refresh = local.monitor.refresh;
      };
      position = {
        x = 0;
        y = 0;
      };
      focus-at-startup = true;
      # Gap between workspaces while switching. Alpha is ignored.
      backdrop-color = "#000000";
    };

    # Render on the GPU wired to the panel. The by-path node stays put across
    # boots; renderD* numbers do not.
    #
    # The open NVIDIA driver reports presentation times that wander, so a
    # 60 Hz animation steps unevenly even when the GPU is idle. Ignoring those
    # timestamps and waiting for each frame to finish before it is queued is
    # what keeps the motion on the vsync.
    layout = {
      # Logical pixels. At scale 1.5 this is ~18 physical px, enough air on 32".
      always-center-single-column  = true;
      gaps = 12;
      center-focused-column = "never";
      preset-column-widths = [
        {proportion = 0.5;}
        {proportion = 0.98;}
        {proportion = 1.0 / 2.0;}
      ];
      default-column-width.proportion = 0.5;
      # Stylix disables the focus-ring and themes the border instead, then we
      # disable that border below — so re-enable the ring explicitly here or
      # nothing gets drawn. Thin, soft Kanagawa foreground on the focused
      # window; transparent on the rest so only the selected one is outlined.
      focus-ring = {
        enable = true;
        width = 3;
        active.color = "#dcd7ba";
        inactive.color = "#00000000";
      };
      border.enable = false;
      # Empty workspace fill. Default is #404040, which shows inside each
      # desktop in the overview wherever the wallpaper doesn't cover.
      background-color = "#000000";
    };

    # Overview ("all desktops"). Default backdrop is #262626.
    overview.backdrop-color = "#000000";

    # noctalia is started as a systemd user service bound to the niri session
    # (see modules/home/noctalia.nix), so no spawn-at-startup needed.

    # This panel is 60 Hz and does not support variable refresh. The default
    # springs, sped up by slowdown < 1, only get a handful of frames, so a
    # full-width column sliding across 32" looks like it skips. A slightly
    # longer ease-out gives the same motion enough frames to read as continuous.
    # Related animations share one curve so a resize and the camera stay in sync
    # with center-focused-column.
    animations = {
      horizontal-view-movement.kind.easing = {
        duration-ms = 280;
        curve = "ease-out-cubic";
      };
      window-movement.kind.easing = {
        duration-ms = 280;
        curve = "ease-out-cubic";
      };
      window-resize.kind.easing = {
        duration-ms = 280;
        curve = "ease-out-cubic";
      };
      workspace-switch.kind.easing = {
        duration-ms = 320;
        curve = "ease-out-cubic";
      };
      window-open.kind.easing = {
        duration-ms = 180;
        curve = "ease-out-expo";
      };
      window-close.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-quad";
      };
    };

    # Fractional scale is sharp only when the client speaks Wayland. Qt's
    # default rounding policy on some builds turns 1.5 into 2 and then
    # downscales, which makes the shell and Qt apps blurry.
    environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
      QT_SCALE_FACTOR_ROUNDING_POLICY = "PassThrough";
      GDK_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # niri-flake's canonical attribute form: `action.<name> = <args>`. No-arg
    # actions take `{ }`; spawn takes a string or a list of argv strings.
    binds = {
      # Launchers
      "Mod+Return".action.spawn = "alacritty";
      # Noctalia v5 IPC: `noctalia msg <command>` (the old `ipc call` form and
      # the `noctalia-shell` binary are gone). The launcher is a named panel.
      "Mod+Space".action.spawn = [
        "noctalia"
        "msg"
        "panel-toggle"
        "launcher"
      ];
      "Mod+B".action.spawn = "zen-beta"; # browser
      "Mod+C".action.spawn = ["vopono-proton" "cursor"]; #
      "Mod+G".action.spawn = ["vopono-proton" "orca"]; #
      "Mod+E".action.spawn = "nautilus"; # file manager

      # Window management
      "Mod+Q".action.close-window = {};
      "Mod+F".action.maximize-column = {};
      "Mod+Shift+F".action.fullscreen-window = {};
      "Mod+W".action.toggle-column-tabbed-display = {};
      "Mod+V".action.toggle-window-floating = {};

      # Focus
      "Mod+H".action.focus-column-left = {};
      "Mod+L".action.focus-column-right = {};
      "Mod+J".action.focus-window-down = {};
      "Mod+K".action.focus-window-up = {};

      # Move
      "Mod+Shift+H".action.move-column-left = {};
      "Mod+Shift+L".action.move-column-right = {};
      "Mod+Shift+J".action.move-window-down = {};
      "Mod+Shift+K".action.move-window-up = {};

      # Sizing
      "Mod+R".action.switch-preset-column-width = {};
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";

      # Workspaces
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;

      # Screenshots
      "Print".action.screenshot = {};
      "Mod+Print".action.screenshot-window = {};
      "Ctrl+Print".action.screenshot-screen = {};

      # Help + session
      "Mod+Shift+Slash".action.show-hotkey-overlay = {};
      "Mod+Shift+E".action.quit = {};

      # Media / brightness keys
      "XF86AudioRaiseVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
      "XF86AudioLowerVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
      "XF86AudioMute".action.spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
      "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
      "XF86AudioNext".action.spawn = ["playerctl" "next"];
      "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
      # Internal panel. modules/nixos/apple-studio-display.nix overrides these to
      # also drive a docked Apple Studio Display when that module is enabled.
      "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "5%+"];
      "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
    };
  };
}
