{pkgs, ...}: {
  home.packages = with pkgs; [
    ollama
    #mods
    aichat
    aider-chat
    #open-webui
  ];
}
