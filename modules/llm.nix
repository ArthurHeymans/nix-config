{pkgs, ...}: {
  # Ollama
  services.ollama = {
    enable = true;
    package = pkgs.ollama;
  };
}
