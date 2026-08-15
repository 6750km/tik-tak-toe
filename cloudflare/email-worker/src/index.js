import { EmailMessage } from "cloudflare:email";

const escapeHtml = (value) => String(value || "")
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&#39;");

const safeHeader = (value) => String(value || "").replace(/[\r\n]/g, " ").slice(0, 160);

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Not found", { status: 404 });

    const data = await request.json();
    const subject = safeHeader(`New Kiki Apps support message: ${data.topic}`);
    const messageId = `<${safeHeader(data.id)}@kiki-apps.uk>`;
    const text = [
      "A new support message was received.",
      "",
      `From: ${data.name} <${data.email}>`,
      `Topic: ${data.topic}`,
      "",
      data.message,
      "",
      `Open message: ${data.messageUrl}`
    ].join("\r\n");
    const html = `<h1>New support message</h1>
      <p><strong>From:</strong> ${escapeHtml(data.name)} &lt;${escapeHtml(data.email)}&gt;</p>
      <p><strong>Topic:</strong> ${escapeHtml(data.topic)}</p>
      <p style="white-space:pre-wrap">${escapeHtml(data.message)}</p>
      <p><a href="${escapeHtml(data.messageUrl)}">Open message</a></p>`;
    const boundary = `kiki-${crypto.randomUUID()}`;
    const raw = [
      "From: Kiki Apps Support <support@kiki-apps.uk>",
      "To: 6750km@gmail.com",
      `Subject: ${subject}`,
      `Message-ID: ${messageId}`,
      "MIME-Version: 1.0",
      `Content-Type: multipart/alternative; boundary=\"${boundary}\"`,
      "",
      `--${boundary}`,
      "Content-Type: text/plain; charset=utf-8",
      "Content-Transfer-Encoding: 8bit",
      "",
      text,
      `--${boundary}`,
      "Content-Type: text/html; charset=utf-8",
      "Content-Transfer-Encoding: 8bit",
      "",
      html,
      `--${boundary}--`,
      ""
    ].join("\r\n");

    await env.SUPPORT_EMAIL.send(new EmailMessage("support@kiki-apps.uk", "6750km@gmail.com", raw));
    return Response.json({ ok: true });
  }
};
