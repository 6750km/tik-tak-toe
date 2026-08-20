const escapeHtml = (value) => String(value || "")
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&#39;");

const sha256 = async (value) => {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
};

const page = (title, body, status = 200) => new Response(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow"><title>${escapeHtml(title)} — Kiki Apps</title>
<link rel="stylesheet" href="/styles.css?v=20260816-3"><link rel="stylesheet" href="/support.css?v=20260816-3"></head>
<body><header class="wrap top"><a class="brand" href="/"><span class="mark">×○</span><span>Kiki Apps</span></a></header>
<main class="wrap"><section class="card">${body}</section></main></body></html>`, {
  status,
  headers: {
    "content-type": "text/html; charset=utf-8",
    "cache-control": "no-store, private",
    "x-robots-tag": "noindex, nofollow"
  }
});

export async function onRequestGet({ params, request, env }) {
  const token = new URL(request.url).searchParams.get("token") || "";
  if (!token || token.length > 160) return page("Link unavailable", "<h1>Link unavailable</h1><p>This message link is invalid.</p>", 404);

  const record = await env.SUPPORT_DB.prepare(`
    SELECT id, created_at, name, email, topic, message, access_token_hash
    FROM support_messages WHERE id = ? LIMIT 1
  `).bind(String(params.id || "")).first();

  if (!record || record.access_token_hash !== await sha256(token)) {
    return page("Link unavailable", "<h1>Link unavailable</h1><p>This message link is invalid or has expired.</p>", 404);
  }

  return page("Support message", `
    <p class="eyebrow">Support message</p>
    <h1>${escapeHtml(record.topic)}</h1>
    <p class="small">Received ${escapeHtml(record.created_at)}</p>
    <h2>From</h2><p>${escapeHtml(record.name)} · <a class="inline-link" href="mailto:${encodeURIComponent(record.email)}">${escapeHtml(record.email)}</a></p>
    <h2>Message</h2><p class="support-message-body">${escapeHtml(record.message)}</p>
  `);
}
