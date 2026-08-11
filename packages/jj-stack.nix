{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:

buildNpmPackage rec {
  pname = "jj-stack";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "keanemind";
    repo = "jj-stack";
    rev = "v${version}";
    hash = "sha256-fk+FZv4lu+noM6ig4NFGAlRy4AWdEjkLIDZZ877bKLs=";
  };

  nodejs = nodejs_22;
  npmDepsHash = "sha256-RVOnxdzSpgyxfS+EZS1oIlX+chUl8GyLXKrmVlEmLPg=";

  meta = {
    description = "CLI tool for creating and managing stacked pull requests on GitHub with Jujutsu";
    homepage = "https://github.com/keanemind/jj-stack";
    license = lib.licenses.mit;
    mainProgram = "jst";
    platforms = lib.platforms.linux;
  };
}
