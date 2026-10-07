import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OAUTH_HOST = process.env.KIMI_CODE_OAUTH_HOST ?? process.env.KIMI_OAUTH_HOST ?? "https://auth.kimi.com";
const CLIENT_ID = "17e5f671-d194-4dfb-9706-5516cb48c098";
const RETRYABLE_STATUSES = new Set([429, 500, 502, 503, 504]);

type Json = Record<string, unknown>;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function detail(body: Json): string {
	const error = body.error;
	if (typeof body.error_description === "string") return body.error_description;
	if (typeof body.message === "string") return body.message;
	if (typeof error === "string") return error;
	if (error && typeof error === "object" && typeof (error as Json).message === "string") {
		return (error as Json).message as string;
	}
	return "unknown error";
}

async function form(path: string, params: Record<string, string>): Promise<{ status: number; body: Json }> {
	const response = await fetch(`${OAUTH_HOST.replace(/\/$/, "")}${path}`, {
		method: "POST",
		headers: { Accept: "application/json", "Content-Type": "application/x-www-form-urlencoded" },
		body: new URLSearchParams(params),
	});
	const body: unknown = await response.json().catch(() => ({}));
	return { status: response.status, body: body && typeof body === "object" ? body as Json : {} };
}

function credentials(body: Json): OAuthCredentials {
	const access = body.access_token;
	const refresh = body.refresh_token;
	const expiresIn = Number(body.expires_in);
	if (typeof access !== "string" || typeof refresh !== "string" || !Number.isFinite(expiresIn) || expiresIn <= 0) {
		throw new Error("Kimi OAuth response is missing token fields");
	}
	return { access, refresh, expires: Date.now() + expiresIn * 1000 };
}

async function poll(deviceCode: string, interval: number, deadline: number): Promise<OAuthCredentials | undefined> {
	if (Date.now() >= deadline) return undefined;
	const token = await form("/api/oauth/token", {
		client_id: CLIENT_ID,
		device_code: deviceCode,
		grant_type: "urn:ietf:params:oauth:grant-type:device_code",
	});
	if (token.status === 200) return credentials(token.body);
	if (token.body.error === "expired_token") return undefined;
	if (token.body.error !== "authorization_pending" && token.body.error !== "slow_down") {
		throw new Error(`Kimi device login failed: ${detail(token.body)}`);
	}
	const nextInterval = token.body.error === "slow_down" ? interval + 5 : interval;
	await sleep(nextInterval * 1000);
	return poll(deviceCode, nextInterval, deadline);
}

async function login(callbacks: OAuthLoginCallbacks, deadline = Date.now() + 15 * 60_000): Promise<OAuthCredentials> {
	if (Date.now() >= deadline) throw new Error("Kimi device login timed out");
	const device = await form("/api/oauth/device_authorization", { client_id: CLIENT_ID });
	if (device.status !== 200) throw new Error(`Kimi device authorization failed: ${detail(device.body)}`);

	const userCode = device.body.user_code;
	const deviceCode = device.body.device_code;
	const verificationUri = device.body.verification_uri_complete ?? device.body.verification_uri;
	if (typeof userCode !== "string" || typeof deviceCode !== "string" || typeof verificationUri !== "string") {
		throw new Error("Kimi device authorization response is missing required fields");
	}
	const interval = Math.max(Number(device.body.interval) || 5, 1);
	callbacks.onDeviceCode({
		userCode,
		verificationUri,
		intervalSeconds: interval,
		expiresInSeconds: Number(device.body.expires_in) || undefined,
	});
	return (await poll(deviceCode, interval, deadline)) ?? login(callbacks, deadline);
}

async function refreshToken(current: OAuthCredentials, attempt = 0): Promise<OAuthCredentials> {
	const token = await form("/api/oauth/token", {
		client_id: CLIENT_ID,
		grant_type: "refresh_token",
		refresh_token: current.refresh,
	});
	if (token.status === 200) return credentials(token.body);
	if (!RETRYABLE_STATUSES.has(token.status) || attempt === 2) {
		throw new Error(`Kimi token refresh failed: ${detail(token.body)}`);
	}
	await sleep(2 ** attempt * 1000);
	return refreshToken(current, attempt + 1);
}

export default function (pi: ExtensionAPI) {
	// Pi already ships the Kimi Coding models and Anthropic-compatible transport.
	pi.registerProvider("kimi-coding", {
		oauth: {
			name: "Kimi Code (Subscription)",
			login,
			refreshToken,
			getApiKey: (credentials) => credentials.access,
		},
	});
}
