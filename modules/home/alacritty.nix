{...}: {
  programs.alacritty = {
    enable = true;

    # Font, colors and opacity are supplied by Stylix.
    settings = {
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
