{lib, ...}: {
  programs.alacritty = {
    enable = true;

    # Font and the accent colors come from Stylix. These overrides replace the
    # gray slots in that palette: base07 is #717c7c, so bold text and bright
    # white were rendering gray on the black background.
    settings = {
      colors = {
        primary = {
          background = lib.mkForce "#000000";
          foreground = lib.mkForce "#dcd7ba";
          bright_foreground = lib.mkForce "#dcd7ba";
        };
        normal.black = lib.mkForce "#000000";
        bright = {
          black = lib.mkForce "#2a2a32";
          white = lib.mkForce "#dcd7ba";
        };
        cursor.text = lib.mkForce "#000000";
        selection.background = lib.mkForce "#141414";
      };
      window = {
        padding = {
          x = 12;
          y = 12;
        };
        decorations = "None";
      };
      cursor.style = {
        shape = "Block";
        blinking = "Never";
      };
      mouse.hide_when_typing = true;
      selection.save_to_clipboard = true;

      # Alacritty has no tabs; these shortcuts open windows in the current cwd.
      keyboard.bindings = [
        {
          key = "Return";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
        {
          key = "N";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
        {
          key = "T";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
      ];
    };
  };
}
