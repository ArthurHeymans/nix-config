{pkgs-unstable, ...}: {
  home.package = with pkgs-unstable; [
    presenterm
  ];
}
