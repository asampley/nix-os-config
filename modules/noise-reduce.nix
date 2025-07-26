{ config, lib, pkgs, ... }:

{
  options.my.noise-reduce = {
    enable = lib.mkEnableOption "add a noise reduction plugin to pipewire";
  };

  config = lib.mkIf config.my.noise-reduce.enable {
    services.pipewire = {
      extraLv2Packages = [ pkgs.rnnoise-plugin ];
      extraConfig.pipewire."91-rt" = {
        "name" = "libpipewire-module-rt";
        "args" = {
          #nice.level   = 20
          #rt.prio      = 88
          #rt.time.soft = -1
          #rt.time.hard = -1
          #rlimits.enabled = true
          #rtportal.enabled = true
          "rtkit.enabled" = true;
          #uclamp.min = 0
          #uclamp.max = 1024
        };
        "flags" = [
          "ifexists"
          "nofail"
        ];
      };
      extraConfig.pipewire."92-latency" = {
        "context.properties" = {
          "link.max-buffers" = 64;
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 512;
          "default.clock.max-quantum" = 8192;
        };
      };
      extraConfig.pipewire."99-input-denoise" = {
        "context.modules" = [
          {
            "name" = "libpipewire-module-filter-chain";
            "args" = {
              "media.name" = "Noise Cancel";
              "node.description" = "rnnoise";
              "audio.position" = [
                "FL"
                "FR"
              ];
              "filter.graph" = {
                "nodes" = [
                  {
                    "name" = "rnnoise";
                    "type" = "ladspa";
                    "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                    "label" = "noise_suppressor_mono";
                    #"type" = "lv2";
                    #"plugin" = "https://github.com/werman/noise-suppression-for-voice#stereo";
                    "control" = {
                      "VAD Threshold (%)" = 50.0;
                      "VAD Grace Period (ms)" = 200;
                      "Retroactive VAD Grace (ms)" = 0;
                    };
                  }
                ];
              };
              "capture.props" = {
                "node.name" = "capture.rnnoise_source";
                "node.passive" = true;
                "audio.rate" = 48000;
              };
              "playback.props" = {
                "node.name" = "rnnoise_source";
                "media.class" = "Audio/Source";
                "audio.rate" = 48000;
              };
            };
          }
        ];
      };
    };
  };
}
