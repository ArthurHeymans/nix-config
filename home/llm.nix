{pkgs-unstable, ...}: {
  home.packages = with pkgs-unstable; [
    ollama
    #mods
    aichat
    aider-chat
    #open-webui
  ];
}
