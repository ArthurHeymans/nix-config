let
  noGitOperationsRule = builtins.toFile "no-git-operations.md" ''
    # Git Operations Rule

    - Do NOT perform any git operations (commit, push, pull, create pull requests, comment on pull requests, or any other git-related actions) unless the user explicitly requests them.
    - Explicit requests mean the user directly asks for a git operation, such as "commit these changes", "push to remote", "create a PR", etc.
    - If code changes are made, do NOT automatically commit them. Wait for explicit user instruction.
    - This rule takes precedence over any default git-related behavior.
  '';
in
{
  providers = {
    openrouter = {
      api = "openai-chat";
      url = "https://openrouter.ai/api/v1";
      keyEnv = "OPENROUTER_API_KEY";
      models = {
        "google/gemini-3-pro-preview" = {};
        "google/gemini-3-flash-preview" = {};
        "z-ai/glm-5" = {};
        "deepseek/deepseek-v3.2" = {};
        "openai/gpt-5.2" = {};
      };
    };
    openrouter_anthropic = {
      api = "anthropic";
      url = "https://openrouter.ai/api/v1";
      keyEnv = "OPENROUTER_API_KEY";
      models = {
        "anthropic/claude-sonnet-4.5" = {};
      };
    };

    anthropic_9e = {
      api = "anthropic";
      url = "https://api.anthropic.com";
      keyEnv = "ANTHROPIC_API_KEY_9E";
      models = {
        "claude-sonnet-4-5-20250929" = {};
        "claude-opus-4-5-20251101" = {};
      };
    };
    deepseek = {
      api = "openai-chat";
      url = "https://api.deepseek.com";
      keyEnv = "DEEPSEEK_API_KEY";
      models = {
        "deepseek-chat" = {};
        "deepseek-coder" = {};
        "deepseek-reasoner" = {};
       };
    };
  };
  defaultModel = "anthropic/claude-sonnet-4.5";
  mcpServers = {
    # memory = {
    #   command = "npx";
    #   args = ["-y" "@modelcontextprotocol/server-memory"];
    # };
    fetch = {
      command = "uvx";
      args = ["mcp-server-fetch" "--ignore-robots-txt"];
    };
    emacs-mcp = {
      command = "npx";
      args = ["@keegancsmith/emacs-mcp-server" ];
    };
    # sequentialthinking = {
    #   command = "npx";
    #   args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
    # };
    #serena = {
    #  command = "uvx";
    #  args = ["--from" "git+https://github.com/oraios/serena" "serena" "start-mcp-server"];
    #};
    # context7 = {
    #   command = "npx";
    #   args = ["-y" "@upstash/context7-mcp"];
    # };
  };
  toolCall = {
      approval = {
        byDefault =  "ask";
        allow = {
          "eca_compact_chat" = {};
          "eca_preview_file_change" = {};
          "eca_read_file" = {};
          "eca_directory_tree" = {};
          "eca_grep" = {};
          "eca_editor_diagnostics" = {};
          "fetch" = {};
          "serena" = {};
        };
        ask  = {};
        deny = {};
      };
  };
  rules = [
    { path = "${noGitOperationsRule}"; }
  ];
}
