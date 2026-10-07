/**
 * DeepSeek Provider Extension
 *
 * Registers DeepSeek as a provider. Reads the API key from the
 * DEEPSEEK_API_KEY environment variable.
 *
 * Usage:
 *   DEEPSEEK_API_KEY=sk-... pi
 *   # Then /model to select a DeepSeek model
 *
 *   # Or directly:
 *   pi --model deepseek/deepseek-flash "hello"
 *
 * Models:
 *   - Only DeepSeek V4.1 (DeepSeek-V4.1-Flash, model id `deepseek-flash`)
 *     is exposed. The legacy `deepseek-v4-flash` /
 *     `deepseek-v4-flash-vision-exp` names are retired server-side and just
 *     route to V4.1-Flash, and `deepseek-chat` / `deepseek-reasoner` are
 *     legacy aliases, so none of them are listed here.
 *   - V4.1 Flash uses the Responses API (`/responses`) and is multimodal:
 *     image input works via `input_image` content parts. It is stateless —
 *     pi sends the full conversation on every request, so `store` /
 *     `previous_response_id` are not used and context caching (KV cache) is
 *     managed automatically by DeepSeek.
 *     https://api-docs.deepseek.com/guides/responses_api
 *
 * Thinking mode:
 *   Thinking is enabled by default (default effort `high`). Pi's thinking
 *   levels map to DeepSeek effort values via `thinkingLevelMap`:
 *     off        → "none"   (thinking disabled)
 *     minimal    → "low"
 *     low        → "low"
 *     medium     → "high"
 *     high       → "high"
 *     xhigh      → "high"
 *     max        → "max"
 *   (DeepSeek remaps `minimal`→`low`, `medium`/`high`/`xhigh`→`high`,
 *   `ultra`→`max` internally, so only `low`/`high`/`max`/`none` are sent.)
 *   The Responses API path sends this as `reasoning: { effort }`.
 *   Note: `temperature` has no effect in thinking mode, and `top_p` is
 *   floored at 0.95.
 *
 * See https://api-docs.deepseek.com/guides/thinking_mode
 *     https://api-docs.deepseek.com/guides/responses_api
 *     https://api-docs.deepseek.com/quick_start/pricing/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Thinking-level → effort mapping for V4.1. Only low/high/max/none are sent;
// DeepSeek remaps the rest internally (see header).
const v41ResponsesEffortMap = {
	off: "none",
	minimal: "low",
	low: "low",
	medium: "high",
	high: "high",
	xhigh: "high",
	max: "max",
};

export default function (pi: ExtensionAPI) {
	pi.registerProvider("deepseek", {
		baseUrl: "https://api.deepseek.com",
		apiKey: "$DEEPSEEK_API_KEY",
		api: "openai-responses",

		models: [
			{
				id: "deepseek-flash",
				name: "DeepSeek V4.1 Flash",
				api: "openai-responses",
				reasoning: true,
				// V4.1 Flash accepts images via `input_image` parts (user /
				// developer messages and tool outputs only).
				input: ["text", "image"],
				// Peak rates per 1M tokens (off-peak is half price; peak
				// hours are 01:00–04:00 and 06:00–10:00 UTC, Mon–Fri).
				cost: { input: 0.3, output: 1.2, cacheRead: 0.006, cacheWrite: 0.3 },
				contextWindow: 1000000,
				maxTokens: 384000,
				thinkingLevelMap: v41ResponsesEffortMap,
				compat: {
					supportsDeveloperRole: false, // DeepSeek treats "developer" as "user"
					supportsStore: false,
					supportsStrictMode: false,
					// Stateless API — skip session-affinity headers.
					sessionAffinityFormat: "openai-nosession",
					// Context caching is automatic; no prompt_cache_retention.
					supportsLongCacheRetention: false,
				},
			},
		],
	});

	// ── Responses API: reasoning-item fixup ──────────────────────────────
	//
	// DeepSeek's Responses API accepts `reasoning` input items but ignores
	// their `summary` / `encrypted_content` fields (see the compatibility
	// notes in the Responses API guide). Pi replays the full reasoning item it
	// captured from the previous response — which can carry those fields — so
	// strip them before sending to keep multi-turn (tool-call) conversations
	// working.

	pi.on("before_provider_request", (event: any, ctx: any) => {
		if (ctx.model?.provider !== "deepseek") return;
		if (ctx.model?.api !== "openai-responses") return;

		const input = event.payload?.input;
		if (!Array.isArray(input)) return;

		for (const item of input) {
			if (item?.type === "reasoning") {
				delete item.summary;
				delete item.encrypted_content;
			}
		}
	});
}
