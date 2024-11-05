{pkgs-unstable, ...}: {
  # Ollama
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama;
  };
}
