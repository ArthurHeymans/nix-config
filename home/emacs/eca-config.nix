{
  providers = {
    openrouter = {
      api = "openai-chat";
      url = "https://openrouter.ai/api/v1";
      keyEnv = "OPENROUTER_API_KEY";
      models = {
        "google/gemini-3-pro-preview" = {};
        "z-ai/glm-4.6" = {};
        "deepseek/deepseek/deepseek-v3.2-exp" = {};
        "openai/gpt-5-codex" = {};
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
      url = "https://api.anthropic.com/v1/messages";
      keyEnv = "ANTHROPIC_API_KEY_9E";
      models = {
        "claude-sonnet-4.5" = {};
      };
    };
  };
  defaultModel = "anthropic/claude-sonnet-4.5";
  mcpServers = {
    memory = {
      command = "npx";
      args = ["-y" "@modelcontextprotocol/server-memory"];
    };
    fetch = {
      command = "uvx";
      args = ["mcp-server-fetch" "--ignore-robots-txt"];
    };
    sequentialthinking = {
      command = "npx";
      args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
    };
    serena = {
      command = "uvx";
      args = ["--from" "git+https://github.com/oraios/serena" "serena" "start-mcp-server"];
    };
    context7 = {
      command = "npx";
      args = ["-y" "@upstash/context7-mcp"];
    };
  };
}
