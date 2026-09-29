-- A push campaign can be cancelled
--
-- The panel's "cancel" on a push campaign set status = 'cancelled', which
-- push_status did not have, so the database refused it and the campaign
-- stayed as it was. The client asked for removal to be reversible rather
-- than a delete, and the other commercial tables (agreements, campaigns)
-- already mark a row rather than remove it, so this adds the word the panel
-- needs. A cancelled campaign keeps its text and can be put back to draft.
--
-- Additive only: existing rows and values are untouched.

alter type push_status add value if not exists 'cancelled';
