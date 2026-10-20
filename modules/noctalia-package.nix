# Noctalia prebuilt with the system glibc patched in.
#
# Why: the cachix prebuilt is linked against the glibc of noctalia's own
# pinned nixpkgs, which is older than this system's. The lock screen
# authenticates through the "login" PAM service (hardcoded upstream in
# src/shell/lockscreen/lock_screen.cpp), whose module paths in /etc/pam.d
# point at this system's linux-pam, built against the newer glibc.
# dlopening those modules into the prebuilt's older glibc fails with
# "GLIBC_2.x not found" (see modules/nixos/noctalia.nix), so every unlock
# fails with rc=7 even with the correct password.
#
# Fix: re-run the prebuilt under the system glibc (interpreter + first
# rpath entry). Cheap — patchelf on the cached binary, no rebuild of the
# C++ tree. Version-agnostic: it patches whatever `packages.default`
# currently is. Drop this file and both `package =` sites when upstream's
# prebuilt links a glibc at least as new as the system's.
{
  pkgs,
  inputs,
}: let
  upstream = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
  pkgs.runCommand "${upstream.name}-system-glibc" {
    nativeBuildInputs = [pkgs.patchelf];
    # runCommand drops upstream's meta, so lib.getExe would warn about a
    # missing meta.mainProgram. The binary is `bin/noctalia`.
    meta = (upstream.meta or {}) // {mainProgram = "noctalia";};
  } ''
    cp -r ${upstream}/. $out/
    chmod -R u+w $out

    # The wrapper execs the prebuilt's absolute store path; point it at the
    # patched copy in this derivation instead.
    sed -i "s|${upstream}/bin/.noctalia-wrapped|$out/bin/.noctalia-wrapped|" $out/bin/noctalia

    # System glibc first in rpath so libc resolves to it; the prebuilt's own
    # (older) glibc dir stays in the path but never wins a lookup.
    patchelf \
      --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
      --set-rpath "${pkgs.glibc}/lib:$(patchelf --print-rpath $out/bin/.noctalia-wrapped)" \
      $out/bin/.noctalia-wrapped
  ''
