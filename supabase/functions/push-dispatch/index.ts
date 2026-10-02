// Sends the push campaigns that are due.
//
// pg_cron calls this once a minute while a campaign in `push_campaigns` is
// `scheduled` for now or earlier (migration 00045). It claims those
// campaigns, sends each to the devices `push_recipients` returns through
// Firebase Cloud Messaging, and records how many Firebase accepted. Android,
// iPhone (Firebase passes it to Apple) and browsers all go the same way.
//
// Environment (tool/setup_push.py sets the first two):
//   PUSH_DISPATCH_SECRET   the header pg_cron sends, from the vault
//   FCM_SERVICE_ACCOUNT    the Firebase service account's JSON key
//   SITE_URL               where a browser notification opens, no trailing /
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY   provided by Supabase
//
// Deployed with JWT checking off (supabase/config.toml), because the caller
// is the database, not a signed-in person; the secret header stands in.

import { createClient } from "npm:@supabase/supabase-js@2";

type Campaign = {
  id: string;
  title: string;
  body: string;
  title_en: string | null;
  body_en: string | null;
  image_url: string | null;
  deep_link: string | null;
};

type Recipient = { id: string; token: string; platform: string; locale: string };

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

const siteUrl = (Deno.env.get("SITE_URL") ?? "https://app.modiin4u.co.il").replace(/\/$/, "");

// Firebase takes one device per request; this many at a time keeps a city's
// worth of devices well inside the function's time limit without tripping
// Firebase's rate limit.
const PARALLEL = 50;
const PAGE = 1000;

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_DISPATCH_SECRET");
  if (!secret || req.headers.get("x-dispatch-secret") !== secret) {
    return new Response("forbidden", { status: 403 });
  }

  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!raw) {
    // Leave the campaigns scheduled: they go out once the key is set.
    return Response.json({ error: "FCM_SERVICE_ACCOUNT is not set" }, { status: 503 });
  }
  const account = JSON.parse(raw) as ServiceAccount;

  const { data: due, error } = await supabase.rpc("push_claim_due", { p_limit: 5 });
  if (error) return Response.json({ error: error.message }, { status: 500 });

  const results = [];
  for (const campaign of (due ?? []) as Campaign[]) {
    results.push(await send(campaign, account));
  }
  return Response.json({ sent: results });
});

async function send(campaign: Campaign, account: ServiceAccount) {
  let accepted = 0;
  let failed = 0;
  const gone: string[] = [];

  try {
    const accessToken = await googleAccessToken(account);
    let after: string | null = null;

    while (true) {
      const { data, error } = await supabase.rpc("push_recipients", {
        p_campaign: campaign.id,
        p_after: after,
        p_limit: PAGE,
      });
      if (error) throw error;
      const page = (data ?? []) as Recipient[];
      if (page.length === 0) break;

      for (let i = 0; i < page.length; i += PARALLEL) {
        const outcomes = await Promise.all(
          page.slice(i, i + PARALLEL).map((r) =>
            sendOne(message(campaign, r), account.project_id, accessToken)
          ),
        );
        outcomes.forEach((outcome, j) => {
          if (outcome === "ok") accepted++;
          else {
            failed++;
            if (outcome === "gone") gone.push(page[i + j].id);
          }
        });
      }
      after = page[page.length - 1].id;
      if (page.length < PAGE) break;
    }

    if (gone.length > 0) {
      await supabase.from("push_devices").update({ is_active: false }).in("id", gone);
    }

    // Sent even when nobody was listening yet: it went out to everyone it
    // could, and it belongs in the bell. Failed only when every one failed.
    const status = accepted === 0 && failed > 0 ? "failed" : "sent";
    await supabase.from("push_campaigns").update({
      status,
      sent_at: new Date().toISOString(),
      sent_count: accepted,
      failed_count: failed,
    }).eq("id", campaign.id);
    return { id: campaign.id, status, accepted, failed };
  } catch (e) {
    await supabase.from("push_campaigns").update({
      status: "failed",
      sent_count: accepted,
      failed_count: failed,
    }).eq("id", campaign.id);
    return { id: campaign.id, status: "failed", error: String(e) };
  }
}

/// The message for one device, in its language.
function message(c: Campaign, r: Recipient) {
  const english = r.locale === "en";
  const title = (english && c.title_en?.trim()) || c.title;
  const body = (english && c.body_en?.trim()) || c.body;
  const link = c.deep_link ?? "";

  // Where a browser opens it: the page itself for an app path, the address
  // for an outside link, with the campaign so the site can count the open.
  const page = link.startsWith("/") ? siteUrl + link : link || siteUrl + "/";
  const webLink = page + (page.includes("?") ? "&" : "?") + "push=" + c.id;

  const image = c.image_url ?? undefined;
  return {
    token: r.token,
    notification: { title, body, ...(image ? { image } : {}) },
    // Read by the app when the notification is tapped.
    data: { campaign_id: c.id, link },
    android: {
      priority: "HIGH",
      notification: { channel_id: "general", icon: "ic_stat_notification", color: "#17A9D0" },
    },
    apns: {
      payload: { aps: { sound: "default", "mutable-content": 1 } },
      ...(image ? { fcm_options: { image } } : {}),
    },
    webpush: {
      notification: { icon: siteUrl + "/icons/Icon-192.png", dir: english ? "ltr" : "rtl" },
      fcm_options: { link: webLink },
    },
  };
}

type Outcome = "ok" | "gone" | "error";

async function sendOne(msg: unknown, projectId: string, accessToken: string): Promise<Outcome> {
  for (let attempt = 0; attempt < 3; attempt++) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: msg }),
      },
    );
    if (res.ok) {
      await res.body?.cancel();
      return "ok";
    }
    const text = await res.text();
    // The device uninstalled the app, or the token was never valid.
    if (res.status === 404 || text.includes("UNREGISTERED")) return "gone";
    if (res.status === 400 && text.includes("registration token")) return "gone";
    // Busy or briefly down: wait and try again; anything else is final.
    if (res.status === 429 || res.status >= 500) {
      await new Promise((ok) => setTimeout(ok, 500 * 2 ** attempt));
      continue;
    }
    console.error("FCM", res.status, text.slice(0, 300));
    return "error";
  }
  return "error";
}

/// An OAuth token for Firebase, from the service account: a JWT signed with
/// its private key, exchanged at Google's token endpoint.
async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const encode = (o: unknown) => base64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = encode({ alg: "RS256", typ: "JWT" }) + "." + encode({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });

  const pem = account.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: unsigned + "." + base64url(new Uint8Array(signature)),
    }),
  });
  if (!res.ok) throw new Error(`Google token: ${res.status} ${await res.text()}`);
  return (await res.json()).access_token;
}

function base64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
