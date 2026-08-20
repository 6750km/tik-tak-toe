const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
});

const clean = (value, max) => String(value || "").replace(/[\r\0]/g, "").trim().slice(0, max);

const sha256 = async (value) => {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
};

export async function onRequestPost({ request, env }) {
  try {
    const form = await request.formData();
    if (form.get("website")) return json({ ok: true });

    const name = clean(form.get("name"), 80);
    const email = clean(form.get("email"), 160);
    const topic = clean(form.get("topic"), 80);
    const message = clean(form.get("message"), 3000);
    const token = clean(form.get("cf-turnstile-response"), 2048);
    if (!name || !/^\S+@\S+\.\S+$/.test(email) || message.length < 10 || !token || form.get("privacy_ack") !== "yes") {
      return json({ error: "Please complete every required field and the security check." }, 400);
    }

    if (!env.TURNSTILE_SECRET_KEY || !env.SUPPORT_DB?.prepare) {
      return json({ error: "Support is temporarily unavailable. Please try again later." }, 503);
    }

    const ip = request.headers.get("CF-Connecting-IP") || "";
    const verification = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ secret: env.TURNSTILE_SECRET_KEY, response: token, remoteip: ip })
    });
    const result = await verification.json();
    if (!result.success) return json({ error: "The security check failed. Please retry." }, 403);

    const id = crypto.randomUUID();
    const accessToken = `${crypto.randomUUID()}${crypto.randomUUID()}`.replaceAll("-", "");
    const accessTokenHash = await sha256(accessToken);
    await env.SUPPORT_DB.prepare(`
      INSERT INTO support_messages (id, name, email, topic, message, ip, user_agent, access_token_hash)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      id,
      name,
      email,
      topic,
      message,
      ip,
      clean(request.headers.get("User-Agent"), 500),
      accessTokenHash
    ).run();

    const messageUrl = `https://kiki-apps.uk/support/message/${encodeURIComponent(id)}?token=${encodeURIComponent(accessToken)}`;
    let notificationSent = false;
    if (env.SUPPORT_NOTIFIER?.fetch) {
      try {
        const notification = await env.SUPPORT_NOTIFIER.fetch("https://support-notifier.internal/notify", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ id, name, email, topic, message, messageUrl })
        });
        notificationSent = notification.ok;
        if (!notification.ok) console.error("Support notification failed", notification.status, await notification.text());
      } catch (error) {
        console.error("Support notification failed", error);
      }
    }

    if (notificationSent) {
      await env.SUPPORT_DB.prepare("UPDATE support_messages SET notified_at = CURRENT_TIMESTAMP WHERE id = ?").bind(id).run();
    }

    return json({ ok: true, id, notificationSent });
  } catch (error) {
    console.error("Support form failed", error);
    return json({ error: "Message could not be sent. Please try again later." }, 500);
  }
}
