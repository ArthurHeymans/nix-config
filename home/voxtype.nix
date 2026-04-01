{ pkgs, ... }:
let
  voxtype-vulkan = pkgs.voxtype.override { vulkanSupport = true; };
in
{
  home.packages = [
    voxtype-vulkan
    pkgs.wtype
  ];

  # Disable built-in hotkey (compositor keybindings are used instead)
  # and enable state_file for start/stop control via `voxtype record`.
  # Run `voxtype setup --download` after first deploy to fetch a model.
  # Based on upstream DEFAULT_CONFIG from config.rs with hotkey disabled
  # for compositor keybinding control.
  # Run `voxtype setup --download` after first deploy to fetch a model.
  xdg.configFile."voxtype/config.toml".text = ''
    state_file = "auto"

    [hotkey]
    key = "SCROLLLOCK"
    modifiers = []
    enabled = false

    [audio]
    device = "default"
    sample_rate = 16000
    max_duration_secs = 60

    [whisper]
    model = "base.en"
    language = "en"
    translate = false

    [output]
    mode = "type"
    fallback_to_clipboard = true
    type_delay_ms = 0

    [output.notification]
    on_recording_start = false
    on_recording_stop = false
    on_transcription = true
  '';

  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype push-to-talk voice-to-text daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${voxtype-vulkan}/bin/voxtype";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
