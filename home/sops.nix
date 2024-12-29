{username, ...}: {
  sops = {
    age = {
      sshKeyPaths = ["/home/${username}/.ssh/id_ed25519"];
    };
    secrets.authinfo = {
      format = "binary";
      sopsFile = ../secrets/authinfo;
      path = "/home/${username}/.authinfo";
    };
  };
}
