{pkgs, ...}: {
  # Ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
}
