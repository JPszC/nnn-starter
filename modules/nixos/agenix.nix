{
  inputs,
  pkgs,
  ...
}: {
  # agenix decrypts .age files at activation using the SSH host key.
  # Host keys only exist once openssh has run once; keep the daemon available
  # but do not open port 22 (firewall stays closed unless you opt in).
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # CLI for `agenix -e secrets/….age` (run from the secrets/ directory).
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # Explicit so it's obvious what decrypts secrets on this box.
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
