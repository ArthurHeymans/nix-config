{
  config,
  username,
  ...
}: {
  sops = {
    age = {
      sshKeyPaths = ["/home/${username}/.ssh/id_ed25519"];
    };
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      authinfo = {
        format = "binary";
        sopsFile = ../secrets/authinfo;
        path = "/home/${username}/.authinfo";
      };
      "environmentVariables/OPENAI_API_KEY" = {};
      "environmentVariables/OPENROUTER_API_KEY" = {};
    };
  };
}
