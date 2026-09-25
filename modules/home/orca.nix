{
  pkgs,
  lib,
  ...
}: let
  # Orca (https://github.com/stablyai/orca) — desktop for a fleet of coding
  # agents. Upstream ships a Linux AppImage; this is not GNOME Orca.
  #
  # The launcher is `orca`. Agent CLIs already on the session PATH (claude,
  # codex, cursor, omp) stay visible: the FHS wrapper prepends its own bins
  # and keeps the inherited PATH. Auth and project state stay runtime-managed.
  #
  # /boot can be an autofs mount that bubblewrap cannot bind inside vopono's
  # namespaces (same workaround as cursor.nix). Orca doesn't need it.
  pname = "orca";
  version = "1.4.211";
  src = pkgs.fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-G3XKlfuC3rdGR0uEXSyrObd06zHnLyhJMp7EC2CMXko=";
  };
  contents = pkgs.appimageTools.extract {inherit pname version src;};
in {
  home.packages = [
    (pkgs.appimageTools.wrapType2 {
      inherit pname version src;

      extraPreBwrapCmds = ''
        ignored+=(/boot)
      '';

      extraInstallCommands = ''
        desktop=$(find ${contents} -name '*.desktop' -print -quit)
        install -Dm644 "$desktop" $out/share/applications/orca.desktop
        sed -i -E 's|^Exec=.*|Exec=orca %U|' $out/share/applications/orca.desktop
        if [[ -d ${contents}/usr/share/icons ]]; then
          mkdir -p $out/share
          cp -r ${contents}/usr/share/icons $out/share/
        fi
      '';

      meta = {
        description = "Desktop for running a fleet of coding agents";
        homepage = "https://github.com/stablyai/orca";
        license = lib.licenses.mit;
        platforms = ["x86_64-linux"];
        sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
        mainProgram = "orca";
      };
    })
  ];
}
