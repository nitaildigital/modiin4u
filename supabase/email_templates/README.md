# The e-mail templates

Supabase's defaults are a bare sentence and a blue link. These are what goes
in their place, at **Authentication → Emails** in the dashboard. Paste the
body of each file into the matching template and save; they are kept here so
the wording is reviewable and does not live only in a web form.

## Why there are no images in them

Almost every mail client blocks remote images until the reader asks for them
— Gmail shows "Display images below", Outlook blocks by default. A design
that leans on a logo file shows most people an empty box where the logo
should be, which on a confirmation e-mail reads as a fake. So the header is a
band of the brand colour with the name set in type: it renders the same
everywhere, needs nothing fetched, and cannot half-arrive. Base64 images are
not a way round it — Gmail strips them.

The one image worth adding later is a logo in the header, once
`app.modiin4u.co.il` has its A record and a certificate. An `https://` URL on
the client's own domain is fetched far more often than one on a bare IP, and
an IP in an e-mail is itself a spam signal. Until then, type.

## Hebrew first

The residents these go to read Hebrew, so that is the first thing in the
message, with English underneath for anyone who does not. Both say the same
thing. The whole document is `dir="rtl"`; the English block sets `dir="ltr"`
on itself so it does not come out reversed.

## Tables, inline styles, and the rest of it

Mail clients are not browsers. Outlook renders with Word, Gmail strips
`<style>` blocks in some views, and flexbox and grid are not usable. So these
are tables with inline styles — the old way, because it is the way that
arrives intact.

## What Supabase substitutes

The dashboard offers seven: `{{ .ConfirmationURL }}`, `{{ .Token }}`,
`{{ .TokenHash }}`, `{{ .SiteURL }}`, `{{ .Email }}`, `{{ .Data }}` and
`{{ .RedirectTo }}`.

These templates use three:

- `{{ .SiteURL }}` and `{{ .TokenHash }}` — the link, built as
  `{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=recovery`
  (or `type=email` for the sign-up confirmation).
- `{{ .Email }}` — printed in the footer beside the "if this was not you"
  line, so a reader can check at a glance that the address is theirs.

### Why not `{{ .ConfirmationURL }}`

It was, and every reset link arrived already spent.

`{{ .ConfirmationURL }}` points straight at Supabase's `/auth/v1/verify`,
which uses up the one-time token the moment anything requests the address.
Gmail, Outlook and most security filters request every link in an incoming
message to check it is safe — so the scanner spent the token, and the person
who clicked a minute later landed on `otp_expired`. Timing was ruled out by
test: an untouched link still worked after three minutes.

`/auth/confirm` is a page in the app. A scanner fetches the page and does not
run it; the token is only spent when the page's own code calls `verifyOTP` in
a real browser. Tested by fetching the link twice as a scanner would and then
opening it: the reset went through.

`{{ .SiteURL }}` is whatever Site URL is set under Authentication → URL
Configuration — `http://45.93.94.49` today. When the domain arrives, change it
there and these keep working.

`{{ .Token }}` is the six-digit code, for a flow that asks the person to type
one instead of following a link. The app does not do that, so it is not used.

## Subject lines

The body is only half of it; the subject is set in the field above it.

- Confirmation: `אישור כתובת האימייל — מודיעין בשבילך`
- Password reset: `איפוס סיסמה — מודיעין בשבילך`

Putting the name in the subject matters more than it looks: it is what a
reader has to go on when deciding whether a message asking them to click
something is genuine.

`confirm_signup.html` is the sign-up confirmation. `reset_password.html` is
the "forgot password" mail. The other templates Supabase offers — magic link,
e-mail change, re-authentication — are not reached by anything the app does
today; if they are turned on later they want the same treatment.
