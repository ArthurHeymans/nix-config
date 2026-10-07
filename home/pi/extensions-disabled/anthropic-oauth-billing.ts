const ANTHROPIC_PROVIDER = "anthropic";
const PI_OAUTH_IDENTITY = "You are Claude Code, Anthropic's official CLI for Claude.";
const SDK_IDENTITY = "You are a Claude agent, built on Anthropic's Claude Agent SDK.";
const BILLING_HEADER_PREFIX = "x-anthropic-billing-header:";
const CCH_SALT = "59cf53e54c78";
const CCH_POSITIONS = [4, 7, 20];
const DEFAULT_CC_VERSION = "2.1.280";
const DEFAULT_ENTRYPOINT = "sdk-cli";
const DROP_PARAGRAPH_ANCHORS = [
	"You are an expert coding assistant operating inside pi, a coding agent harness.",
	"Pi documentation (read only when the user asks about pi itself, its SDK, extensions, themes, skills, or TUI):",
	"@mariozechner/pi-coding-agent",
	"docs/extensions.md",
	"docs/themes.md",
	"docs/skills.md",
	"docs/prompt-templates.md",
	"docs/tui.md",
	"docs/keybindings.md",
	"docs/sdk.md",
	"docs/custom-provider.md",
	"docs/models.md",
	"docs/packages.md",
	"When working on pi topics, read the docs and examples",
	"Always read pi .md files completely",
];

function isRecord(value: unknown): value is Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}

function getEnv(name: string, fallback: string): string {
	const value = process.env[name]?.trim();
	return value && value.length > 0 ? value : fallback;
}

function isTruthyEnv(name: string): boolean {
	const value = process.env[name]?.trim().toLowerCase();
	return value === "1" || value === "true";
}

function getTextEncoder(): TextEncoder {
	return new TextEncoder();
}

async function sha256Hex(text: string): Promise<string> {
	const bytes = getTextEncoder().encode(text);
	const digest = await crypto.subtle.digest("SHA-256", bytes);
	return Array.from(new Uint8Array(digest))
		.map((byte) => byte.toString(16).padStart(2, "0"))
		.join("");
}

function extractFirstUserMessageText(messages: unknown[]): string {
	for (const message of messages) {
		if (!isRecord(message) || message.role !== "user") continue;
		const content = message.content;
		if (typeof content === "string") return content;
		if (!Array.isArray(content)) continue;
		for (const block of content) {
			if (!isRecord(block)) continue;
			if (block.type === "text" && typeof block.text === "string") {
				return block.text;
			}
		}
	}
	return "";
}

async function buildBillingHeader(messages: unknown[]): Promise<string | null> {
	const version = getEnv("PI_ANTHROPIC_OAUTH_CC_VERSION", DEFAULT_CC_VERSION);
	const entrypoint = getEnv("PI_ANTHROPIC_OAUTH_ENTRYPOINT", DEFAULT_ENTRYPOINT);
	const firstUserText = extractFirstUserMessageText(messages);
	if (!firstUserText) return null;

	const cch = (await sha256Hex(firstUserText)).slice(0, 5);
	const sampledChars = CCH_POSITIONS.map((index) => firstUserText[index] ?? "0").join("");
	const suffix = (await sha256Hex(`${CCH_SALT}${sampledChars}${version}`)).slice(0, 3);
	return `${BILLING_HEADER_PREFIX} cc_version=${version}.${suffix}; cc_entrypoint=${entrypoint}; cch=${cch};`;
}

function getSystemText(block: unknown): string | null {
	if (typeof block === "string") return block;
	if (!isRecord(block)) return null;
	return typeof block.text === "string" ? block.text : null;
}

function makeTextBlock(text: string, source?: unknown): Record<string, unknown> {
	if (isRecord(source)) {
		return { ...source, type: "text", text };
	}
	return { type: "text", text };
}

function isAnthropicMessagesPayload(payload: unknown): payload is { system?: unknown; messages: unknown[] } {
	return isRecord(payload) && Array.isArray(payload.messages);
}

function hasOauthIdentity(system: unknown): boolean {
	if (!Array.isArray(system) || system.length === 0) return false;
	return system.some((block) => {
		const text = getSystemText(block);
		return text === PI_OAUTH_IDENTITY || text === SDK_IDENTITY;
	});
}

function sanitizeSystemText(text: string): string {
	const paragraphs = text
		.split(/\n\n+/)
		.map((paragraph) => paragraph.trim())
		.filter(Boolean)
		.filter((paragraph) => {
			if (paragraph.includes(PI_OAUTH_IDENTITY) || paragraph.includes(SDK_IDENTITY)) return false;
			return !DROP_PARAGRAPH_ANCHORS.some((anchor) => paragraph.includes(anchor));
		});

	return paragraphs.join("\n\n").trim();
}

function sanitizeMovedSystemTextBlocks(system: unknown[] | undefined): string[] {
	if (!Array.isArray(system)) return [];
	const movedTexts: string[] = [];

	for (const block of system) {
		const text = getSystemText(block);
		if (!text) continue;
		if (text.startsWith(BILLING_HEADER_PREFIX)) continue;
		if (text === PI_OAUTH_IDENTITY || text === SDK_IDENTITY) continue;
		const sanitized = sanitizeSystemText(text);
		if (sanitized) movedTexts.push(sanitized);
	}

	return movedTexts;
}

function prependSystemTextToFirstUser(messages: unknown[], text: string): unknown[] {
	const nextMessages = [...messages];
	for (let i = 0; i < nextMessages.length; i++) {
		const message = nextMessages[i];
		if (!isRecord(message) || message.role !== "user") continue;
		const currentContent = message.content;

		if (typeof currentContent === "string") {
			nextMessages[i] = { ...message, content: `${text}\n\n${currentContent}` };
			return nextMessages;
		}

		if (Array.isArray(currentContent)) {
			nextMessages[i] = {
				...message,
				content: [{ type: "text", text }, ...currentContent],
			};
			return nextMessages;
		}

		nextMessages[i] = { ...message, content: text };
		return nextMessages;
	}

	return nextMessages;
}

function buildOauthSystemBlocks(header: string): unknown[] {
	return [
		{ type: "text", text: header },
		{ type: "text", text: SDK_IDENTITY },
	];
}

export default function anthropicOauthBillingExtension(pi: any) {
	pi.on("before_provider_request", async (event: any, ctx: any) => {
		if (ctx.model?.provider !== ANTHROPIC_PROVIDER) return;
		if (!isAnthropicMessagesPayload(event.payload)) return;
		if (!hasOauthIdentity(event.payload.system)) return;

		const header = await buildBillingHeader(event.payload.messages);
		if (!header) return;

		const movedTexts = sanitizeMovedSystemTextBlocks(
			Array.isArray(event.payload.system) ? event.payload.system : undefined,
		);
		const movedPrefix = movedTexts.join("\n\n").trim();
		const keepSystemPrompt = isTruthyEnv("PI_ANTHROPIC_OAUTH_KEEP_SYSTEM_PROMPT");

		return {
			...event.payload,
			system: keepSystemPrompt
				? [
					makeTextBlock(header),
					makeTextBlock(SDK_IDENTITY),
					...movedTexts.map((text) => makeTextBlock(text)),
				]
				: buildOauthSystemBlocks(header),
			messages:
				!keepSystemPrompt && movedPrefix
					? prependSystemTextToFirstUser(event.payload.messages, movedPrefix)
					: event.payload.messages,
		};
	});
}
