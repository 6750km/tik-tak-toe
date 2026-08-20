import assert from "node:assert/strict";
import test from "node:test";

import { onRequestPost } from "../functions/api/support.js";

const originalFetch = globalThis.fetch;

const requestFor = (token = "turnstile-token") => {
  const form = new FormData();
  form.set("name", "QA User");
  form.set("email", "qa@example.com");
  form.set("topic", "Gameplay");
  form.set("message", "This is a support test message.");
  form.set("privacy_ack", "yes");
  form.set("cf-turnstile-response", token);
  return new Request("https://kiki-apps.uk/api/support", { method: "POST", body: form });
};

const makeEnvironment = () => {
  const writes = [];
  return {
    writes,
    env: {
      TURNSTILE_SECRET_KEY: "test-secret",
      SUPPORT_DB: {
        prepare(sql) {
          return {
            bind(...values) {
              return {
                async run() {
                  writes.push({ sql, values });
                }
              };
            }
          };
        }
      },
      SUPPORT_NOTIFIER: {
        async fetch() {
          return Response.json({ ok: true });
        }
      }
    }
  };
};

test.afterEach(() => {
  globalThis.fetch = originalFetch;
});

test("returns JSON and stores a valid support message", async () => {
  globalThis.fetch = async () => Response.json({ success: true });
  const { env, writes } = makeEnvironment();

  const response = await onRequestPost({ request: requestFor(), env });
  const data = await response.json();

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("content-type"), "application/json; charset=utf-8");
  assert.equal(data.ok, true);
  assert.equal(data.notificationSent, true);
  assert.equal(writes.filter(({ sql }) => sql.includes("INSERT INTO support_messages")).length, 1);
});

test("rejects a repeated Turnstile token before the second database write", async () => {
  let verificationCount = 0;
  globalThis.fetch = async () => Response.json({ success: verificationCount++ === 0 });
  const { env, writes } = makeEnvironment();

  const first = await onRequestPost({ request: requestFor("one-time-token"), env });
  const second = await onRequestPost({ request: requestFor("one-time-token"), env });
  const secondData = await second.json();

  assert.equal(first.status, 200);
  assert.equal(second.status, 403);
  assert.equal(secondData.error, "The security check failed. Please retry.");
  assert.equal(writes.filter(({ sql }) => sql.includes("INSERT INTO support_messages")).length, 1);
});
