import assert from "node:assert/strict";
import test from "node:test";

import { buildSupportEmail } from "../src/message.js";

const message = {
  id: "message-id",
  name: "QA User",
  email: "qa@example.com",
  topic: "Gameplay",
  message: "A test support message.",
  messageUrl: "https://kiki-apps.uk/support/message/message-id?token=test-token"
};

test("sets Reply-To to the support sender and keeps padded HTML containers", () => {
  const raw = buildSupportEmail(message);

  assert.match(raw, /\r\nReply-To: qa@example\.com\r\n/);
  assert.match(raw, /padding:32px 16px/);
  assert.match(raw, /padding:36px 34px/);
  assert.match(raw, /href="https:\/\/kiki-apps\.uk\/support\/message\/message-id\?token=test-token"/);
});

test("removes CR and LF characters from email headers", () => {
  const raw = buildSupportEmail({
    ...message,
    email: "qa@example.com\r\nBcc: attacker@example.com",
    topic: "Gameplay\r\nBcc: attacker@example.com"
  });
  const headers = raw.split("\r\n\r\n", 1)[0];

  assert.doesNotMatch(headers, /\r\nBcc:/);
  assert.match(headers, /Reply-To: qa@example\.com  Bcc: attacker@example\.com/);
});
