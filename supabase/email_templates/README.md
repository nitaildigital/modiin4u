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

These templates use two:

- `{{ .ConfirmationURL }}` — the link, already carrying the token and the
  redirect it should return to. Nothing is appended to it; it arrives whole.
- `{{ .Email }}` — printed in the footer beside the "if this was not you"
  line, so a reader can check at a glance that the address is theirs.

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
