{pkgs, ...}: {
  home.packages = with pkgs; [
    ollama # --> slow to build
    mistral-rs
    #mods
    aichat
    # (aider-chat-full.overridePythonAttrs (oldAttrs: {
    #   src = pkgs.fetchFromGitHub {
    #     owner = "quinlanjager";
    #     repo = "aider";
    #     rev = "36f8a4d2d5bd576e006b38d27c973e26160a652b";
    #     hash = "sha256-30Ym/lmP7XNXqnK8u72U8yy7hIKT6TFj04l6+X8jLgs=";
    #   };
    #   version = "0.85.0";
    #   doCheck = false;
    #   dependencies = oldAttrs.dependencies ++ (with pkgs.python312Packages; [
    #     httpx-sse
    #     pydantic-settings
    #     sse-starlette
    #     starlette
    #     uvicorn
    #     mcp
    #   ]);
    # }))
    (aider-chat.overridePythonAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "Aider-AI";
        repo = "aider";
        rev = "3b919646a5a61926f7c7d011f43e686fec1bd370";
        hash = "sha256-WJklWFS1hvtjkm4T8NdmDWSNIZ3piRnOxCytCA2UqsE=";
      };
      version = "0.85.5";
    }))
    #open-webui
  ];
}
