const escapeHtml = (value) => String(value || "")
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&#39;");

const safeHeader = (value) => String(value || "").replace(/[\r\n]/g, " ").slice(0, 160);

export const buildSupportEmail = (data) => {
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
  const html = `<!doctype html><html lang="en"><body style="margin:0;background:#f4f3fb;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif;color:#191824">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:#f4f3fb"><tr><td align="center">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:552px"><tr><td style="padding:32px 16px">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:#ffffff;border-radius:24px"><tr><td style="padding:36px 34px">
          <h1 style="margin:0 0 24px;font-size:26px">New support message</h1>
          <p style="margin:0 0 12px;line-height:1.5"><strong>From:</strong> ${escapeHtml(data.name)} &lt;${escapeHtml(data.email)}&gt;</p>
          <p style="margin:0 0 20px;line-height:1.5"><strong>Topic:</strong> ${escapeHtml(data.topic)}</p>
          <p style="margin:0 0 24px;line-height:1.55;white-space:pre-wrap">${escapeHtml(data.message)}</p>
          <p style="margin:0"><a href="${escapeHtml(data.messageUrl)}" style="display:inline-block;padding:12px 18px;border-radius:12px;background:#6257e8;color:#ffffff;text-decoration:none;font-weight:700">Open message</a></p>
        </td></tr></table>
      </td></tr></table>
    </td></tr></table>
  </body></html>`;
  const boundary = `kiki-${crypto.randomUUID()}`;
  return [
    "From: Kiki Apps Support <support@kiki-apps.uk>",
    "To: 6750km@gmail.com",
    `Reply-To: ${safeHeader(data.email)}`,
    `Subject: ${subject}`,
    `Message-ID: ${messageId}`,
    "MIME-Version: 1.0",
    `Content-Type: multipart/alternative; boundary="${boundary}"`,
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
};
