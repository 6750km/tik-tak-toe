import { EmailMessage } from "cloudflare:email";
import { buildSupportEmail } from "./message.js";

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Not found", { status: 404 });

    const data = await request.json();
    const raw = buildSupportEmail(data);

    await env.SUPPORT_EMAIL.send(new EmailMessage("support@kiki-apps.uk", "6750km@gmail.com", raw));
    return Response.json({ ok: true });
  }
};
