{ config, pkgs, ... }:
let
  # The upstream x86-64-v3 RUSTFLAGS require AVX2; older hosts need v2.
  voxtype = pkgs.voxtype.overrideAttrs (old: {
    env = (old.env or { }) // {
      RUSTFLAGS = "-C target-cpu=x86-64-v2";
    };
  });
in
{
  home.packages = [
    voxtype
    pkgs.wtype
  ];

  # Disable built-in hotkey (compositor keybindings are used instead)
  # and enable state_file for start/stop control via `voxtype record`.
  # Audio is sent to OpenAI after the recording stops; no local model is needed.
  xdg.configFile."voxtype/config.toml".text = ''
    state_file = "auto"
    engine = "whisper"

    [hotkey]
    key = "SCROLLLOCK"
    modifiers = []
    enabled = false

    [osd]
    enabled = false

    [audio]
    device = "default"
    sample_rate = 16000
    max_duration_secs = 60

    [whisper]
    mode = "remote"
    remote_endpoint = "https://api.openai.com"
    remote_model = "gpt-transcribe"
    remote_timeout_secs = 60
    language = "auto"
    initial_prompt = "Firmware and hardware engineering discussion. Repo is shorthand for repository. Terms include Caliptra, Caliptra MCU, Caliptra Subsystem, coreboot, oreboot, SeaBIOS, U-Boot, Slim Bootloader, TamaGo, Embassy, RISC-V, ARM Trusted Firmware, ACPI, PCIe, CBFS, flashrom, SPI, I2C, I3C, UART, GPIO, JTAG, SWD, MMIO, DMA, MCTP, SPDM, PLDM, TDISP, DPE, FMC, devicetree, bootloader, baud rate, ROM, SoC, MCU, BMC, FPGA, QEMU, SystemRDL, X.509, root of trust, secure boot, measured boot."

    [output]
    mode = "type"
    fallback_to_clipboard = true
    type_delay_ms = 0

    [output.notification]
    on_recording_start = false
    on_recording_stop = false
    on_transcription = true

    [text]
    spoken_punctuation = true

    [text.replacements]
    "calyptra" = "Caliptra"
    "calliptra" = "Caliptra"
    "core boot" = "coreboot"
    "flash rom" = "flashrom"
    "ore boot" = "oreboot"
    "risk five" = "RISC-V"
    "risk v" = "RISC-V"
    "sea bios" = "SeaBIOS"
    "system r d l" = "SystemRDL"
  '';

  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype push-to-talk voice-to-text daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellScript "voxtype-with-openai-key" ''
        export VOXTYPE_WHISPER_API_KEY="$(< ${
          config.sops.secrets."environmentVariables/OPENAI_API_KEY".path
        })"
        exec ${voxtype}/bin/voxtype
      ''}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
