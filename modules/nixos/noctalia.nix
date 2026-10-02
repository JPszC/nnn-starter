{
  pkgs,
  inputs,
  ...
}: {
  # Noctalia's NixOS module enables the system-level support it needs. The shell
  # itself is launched per-user from home (see modules/home/noctalia.nix), so we
  # only opt into the recommended companion services here.
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
    # Use upstream's prebuilt package straight from noctalia.cachix.org instead
    # of rebuilding the (large, ~hour) C++ tree against our nixpkgs —
    # re-linked onto the system glibc so the lock screen can load the
    # system's PAM modules (see ../noctalia-package.nix for why).
    package = import ../noctalia-package.nix {inherit pkgs inputs;};
  };
}
