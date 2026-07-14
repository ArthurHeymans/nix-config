{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Arthur Heymans";
        email = "arthur@aheymans.xyz";
      };
      github = {
        user = "ArthurHeymans";
        "github.com".user = "ArthurHeymans";
      };
    };
    signing = {
      signByDefault = true;
      key = "4401A5C26DF3FFFDF472F84AA1D13A950A6651BB";
      format = "openpgp";
    };
    ignores = [
      ".aider*"
      ".envrc"
      ".direnv"
      ".direnv/*"
      ".dir-locals.el"
      ".pi-lens"
      ".pi"
      ".pi-subagents"
      ".local"
    ];
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      signing = {
        behavior = "own";
        backend = "gpg";
        key = "4401A5C26DF3FFFDF472F84AA1D13A950A6651BB";
      };
      user = {
        name = "Arthur Heymans";
        email = "arthur@aheymans.xyz";
      };
    };
  };
}
