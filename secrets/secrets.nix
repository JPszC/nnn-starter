# Used ONLY by the `agenix` CLI (not imported into NixOS).
# From secrets/:  agenix -e pangolin.env.age
#
# After first boot with openssh enabled, paste the host pubkey:
#   cat /etc/ssh/ssh_host_ed25519_key.pub
#
# Re-encrypt existing secrets after changing keys:
#   agenix -r
let
  # System key — required so NixOS can decrypt at activation.
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBCzjz+xqebk/eWLbG2HFHAaWzZCQWnGoqxLvZXlg1d root@jpszc";

  # Your user key — required so you can edit secrets without root.
  # From: cat ~/.ssh/id_rsa.pub  (or prefer an ed25519 key if you have one)
  user = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6rcJI/Qs1aVnk6ShIcfm5lhj2t8kS9r84skhaMRhBHzxTJlzs2gFhAtH1dKtERBGOHiM5ca9N6LFNRWQ44XHnei1CzSkIy7L+ZEFAbx+BfMUIo7AKU5b7fE+yuJy/kXJo+giP9ROxNdHwLNpCgW28Mn2y395YIHj92u9bcJeofyUx55KL/fuvDkPP3Q7Hx2EFYnrz4m43D+g3l5/sitTLzOmzl7GhL2rZ/WgAmOoVEqY99UldvwkMDhiqo6oNhEQ1acsnfD09ZROUxoii8a7k9PDUnDe1+CkkAmyr6ea9hLXUZHbCieRX8QfeRztIC+AjNDxVW3dvh5OOb6Fa7Mzs3Ll621bq1SZUTf2GI1lkkWeWu8GfmU1hlFqwK8iEFF9JmoL+urWTiz2jG4V5duSJRml0WywhJBiE5NzHCUEqAXNa2Qa2hYSGwE2T5FXXbUooPq5PucloaiKATEXAgvNw2h9yxfnPxWjRtKi4nT97V/IRK5m9LWcxgXfR4UWiK6M= user@DESKTOP-8PN5EV6";
in {
  "pangolin.env.age".publicKeys = [
    system
    user
  ];
}
