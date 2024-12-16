{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.mbsync.enable = true;
  programs.msmtp.enable = true;

  accounts.email = {
    maildirBasePath = ".mail";
    accounts = {
      "aheymans" = {
        primary = true;
        address = "arthur@aheymans.xyz";
        userName = "arthur@aheymans.xyz";
        realName = "Arthur Heymans";
        passwordCommand = "${pkgs.gnupg}/bin/gpg -q --for-your-eyes-only  --no-tty -d ~/.authinfo.gpg | awk -v machine=\"aheymans\" -v login=\"arthur@aheymans.xyz\" '$1 == \"machine\" && $2 == machine && $4 == login && $5 == \"password\" {print $6}'";
        imap.host = "imap.gmail.com";
        smtp.host = "smtp.gmail.com";
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          patterns = ["*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail"];
          extraConfig = {
            channel = {
              Sync = "All";
            };
            account = {
              Timeout = 120;
              PipelineDepth = 1;
            };
          };
        };
        mu.enable = true;
        msmtp.enable = true;
      };
      "gmail" = {
        address = "arthurphilippeheymans@gmail.com";
        userName = "arthurphilippeheymans@gmail.com";
        realName = "Arthur Heymans";
        passwordCommand = "${pkgs.gnupg}/bin/gpg -q --for-your-eyes-only  --no-tty -d ~/.authinfo.gpg | awk -v machine=\"gmail\" -v login=\"arthurphilippeheymans@gmail.com\" '$1 == \"machine\" && $2 == machine && $4 == login && $5 == \"password\" {print $6}'";
        imap.host = "imap.gmail.com";
        smtp.host = "smtp.gmail.com";
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          patterns = ["*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail"];
          extraConfig = {
            channel = {
              Sync = "All";
            };
            account = {
              Timeout = 120;
              PipelineDepth = 1;
            };
          };
        };
        mu.enable = true;
        msmtp.enable = true;
      };
      "9elements" = {
        address = "arthur.heymans@9elements.com";
        userName = "arthur.heymans@9elements.com";
        realName = "Arthur Heymans";
        passwordCommand = "${pkgs.gnupg}/bin/gpg -q --for-your-eyes-only  --no-tty -d ~/.authinfo.gpg | awk -v machine=\"9elements\" -v login=\"arthur.heymans@9elements.com\" '$1 == \"machine\" && $2 == machine && $4 == login && $5 == \"password\" {print $6}'";
        imap.host = "imap.gmail.com";
        smtp.host = "smtp.gmail.com";
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          patterns = ["*"];
          extraConfig = {
            channel = {
              Sync = "All";
            };
            account = {
              Timeout = 120;
              PipelineDepth = 1;
            };
          };
        };
        mu.enable = true;
        msmtp.enable = true;
      };
    };
  };
}
