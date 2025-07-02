{pkgs, ...}: {
  home.packages = with pkgs; [
    ollama # --> slow to build
    mistral-rs
    #mods
    aichat
    (aider-chat-full.overridePythonAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "quinlanjager";
        repo = "aider";
        rev = "fa78cd7e1d421ccd1c797b2e7dd4abf24802c87d";
        hash = "sha256-hFhg8Jc3cZSMTC3+ioRqAzYzskeprwJb2mKW99lT9qQ=";
      };
      version = "0.85.0";
      doCheck = false;
      dependencies = oldAttrs.dependencies ++ (with pkgs.python312Packages; [
        httpx-sse
        pydantic-settings
        sse-starlette
        starlette
        uvicorn
        mcp
      ]);
    }))
    #open-webui
  ];
}
