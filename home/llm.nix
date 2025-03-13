{pkgs, ...}: {
  home.packages = with pkgs; [
    #ollama --> slow to build
    vllm
    #mods
    aichat
    aider-chat.withPlaywright
    #open-webui
  ];
}
