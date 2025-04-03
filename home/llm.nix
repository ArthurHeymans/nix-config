{pkgs, ...}: {
  home.packages = with pkgs; [
    #ollama --> slow to build
    mistral-rs
    #mods
    aichat
    aider-chat
    #open-webui
  ];
}
