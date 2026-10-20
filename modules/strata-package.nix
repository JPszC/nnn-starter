# Strata (https://github.com/lgse/strata) — keyboard-first GTK4 file manager.
#
# Not in nixpkgs, and upstream's flake-less repo only ships an Arch/AUR
# binary, so we build it from the tagged source with rustPlatform.
#
# Strata runs every untrusted preview parser inside bubblewrap and by default
# assumes an FHS layout (`/usr/bin`, `/usr`). Upstream documents the Nix
# recipe in docs/preview-sandbox.md: point the *compile-time* knobs below at
# store paths so the host finds `bwrap` and the sandbox binds `/nix/store`
# instead of `/usr`. Without these, previews fail closed.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  glib,
  gtk4,
  gtksourceview5,
  poppler,
  fontconfig,
  gdk-pixbuf,
  cairo,
  pango,
  gst_all_1,
  bubblewrap,
  util-linux,
  ffmpeg,
  ffmpegthumbnailer,
  imagemagick,
  xdg-utils,
  gvfs,
}: let
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "lgse";
    repo = "strata";
    rev = "v${version}";
    hash = "sha256-dFNsFCnkeZs0VwmYRyu+6Jh8XxJzv+agUlP70Fdxa5Q=";
  };

  # Helpers the sandboxed preview workers execute (video/RAW/etc.).
  sandboxBins = lib.concatMapStringsSep ":" (p: "${lib.getBin p}/bin") [
    ffmpeg
    ffmpegthumbnailer
    imagemagick
  ];

  # Host-side helpers (searched only if they canonicalize under /nix/store).
  trustedBins = lib.concatMapStringsSep ":" (p: "${lib.getBin p}/bin") [
    bubblewrap
    xdg-utils
  ];
in
  rustPlatform.buildRustPackage {
    pname = "strata";
    inherit version;

    inherit src;

    # No git dependencies, so the lockfile alone pins everything.
    cargoLock.lockFile = "${src}/Cargo.lock";

    nativeBuildInputs = [
      pkg-config
      wrapGAppsHook4
      glib # glib-compile-resources for build.rs
    ];

    buildInputs =
      [
        glib
        gtk4
        gtksourceview5
        poppler
        fontconfig
        gdk-pixbuf
        cairo
        pango
        gvfs
      ]
      ++ (with gst_all_1; [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-libav
      ]);

    env = {
      STRATA_TRUSTED_COMMAND_PATH = trustedBins;
      STRATA_SANDBOX_PATH = sandboxBins;
      STRATA_SANDBOX_ROOT = "/nix/store";
      STRATA_SANDBOX_PRLIMIT = "${lib.getBin util-linux}/bin/prlimit";
      STRATA_SANDBOX_GDK_PIXBUF_MODULE_FILE = "${gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
      STRATA_BUILD_COMMIT = "v${version}";
    };

    # The test suite needs a display, bubblewrap user namespaces and gvfs,
    # none of which exist in the build sandbox.
    doCheck = false;

    postInstall = ''
      install -Dm644 data/io.github.lgse.Strata.desktop \
        $out/share/applications/io.github.lgse.Strata.desktop
      substituteInPlace $out/share/applications/io.github.lgse.Strata.desktop \
        --replace-fail "Exec=strata " "Exec=$out/bin/strata "

      install -Dm644 data/icons/scalable/apps/io.github.lgse.Strata.svg \
        $out/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg

      # org.freedesktop.FileManager1 ("Open file location" from browsers etc.)
      install -Dm644 data/io.github.lgse.Strata.FileManager1.service \
        $out/share/dbus-1/services/io.github.lgse.Strata.FileManager1.service
      substituteInPlace $out/share/dbus-1/services/io.github.lgse.Strata.FileManager1.service \
        --replace-fail "Exec=/usr/bin/strata " "Exec=$out/bin/strata "
    '';

    meta = {
      description = "Fast, keyboard-first file manager for Linux";
      homepage = "https://github.com/lgse/strata";
      license = lib.licenses.mit;
      mainProgram = "strata";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
