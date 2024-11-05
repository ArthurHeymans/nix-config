{pkgs-unstable, ...}: {
  home.packages = with pkgs-unstable; [
    ollama
    mods
    aider-chat
    #open-webui
  ];
}
