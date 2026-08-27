# Server-Side SFTP Delivery Pipeline

**Status:** Backend shipped · Qt client in progress
**Version:** 1.1 · Updated August 2026
**Repos:** `smartcheq_website_ror` (backend) · `smartcheq_sahara` (desktop client)

> Canonical source for the ERB page at `bearercore.com/docs/sftp-delivery-pipeline`.
> Moving CVIB bundle delivery off the Qt client's `sshpass` path and onto the
> server, where the recipient bank's SFTP credentials live AES-256-GCM encrypted
> and are decrypted only at the moment of transfer.

---

## §1 Background & Objectives

Today the Qt client packages the bundle **and** performs the SFTP transfer itself,
driving an `sshpass` batch file from a QtConcurrent thread. Connection details —
including the bank's SFTP password — are hand-entered at delivery time and never
leave the operator's workstation. Rails only sends a post-transfer notification
email.

That places a live counterparty credential on every operator machine and makes
delivery unauditable server-side. The new pipeline centralizes the credential
(encrypted at rest, on the server) and makes the server the single, logged actor
that connects out to the bank.

| | Before — client-driven | After — server-driven |
|---|---|---|
| Transfer | Qt packages ZIP **and** runs `sshpass` to push it | Qt uploads the ZIP to Rails; the **server** pushes via SFTP |
| Credentials | Hand-entered per delivery, on the workstation | Stored **AES-256-GCM encrypted**, decrypted in-process only |
| Notification | Rails sends a notification email only | Delivery + notification are one auditable server flow |
| Audit | No server-side delivery record or retry | `CvibDelivery` ledger with retry & alerting |

---

## §2 End-to-End Pipeline Flow

Hand-off happens after `confirm_manifest`, once the batch is `active`. Identity is
persisted on the batch, so every step after upload resolves from the batch record —
no per-request trust.

1. **Qt client — package & upload.** After manifest confirmation, POST the ZIP to
   `upload_bundle` with its SHA-256 and the recipient identity (SWIFT, email, bank
   name).
2. **Rails · controller — persist, spool & verify.** Writes recipient fields onto
   the batch, spools the file to disk, and rejects it unless the computed SHA-256
   matches what Qt declared.
3. **Rails · per-bank gate — require an active connection.**
   `Sftp.for_delivery(swift)` must return an active, test-passed connection. If
   none: hard-fail — `pending_no_connection`, admin alert, HTTP 409. No
   email-attachment fallback.
4. **Rails · `CvibSftpDeliveryJob` — decrypt & push.** Resolves host/dir/user + the
   decrypted password (the **only** decryption point at delivery), pushes via
   `ScSftp`, and writes a ledger row.
5. **Rails · on success — record & notify.** Marks `delivered` (host, remote path,
   bytes), fires the attachment-less notification email, and purges the spooled ZIP.
   On success logs `[ok] Delivery notification email dispatched to <recipient>`.

### Mail transport & secrets

`Cvib::SendBundleEmailService` sends via the Gmail API and resolves its OAuth
credentials **at call time** from ENV — `GMAIL_CLIENT_ID` / `GMAIL_CLIENT_SECRET` /
`GMAIL_REFRESH_TOKEN` (the Capistrano-linked `shared/.env`) — with a
`Rails.application.credentials.gmail_oauth` fallback. **No OAuth secret lives in
source.** Rotating the client is a `shared/.env` edit + `cap production
sidekiq:restart`, no code change. (The previously hardcoded client was deleted in
Google Cloud → `deleted_client`, which silently broke every delivery email while
SFTP still succeeded — hence the extraction.)

The notification body (HTML + plain text) surfaces the **Destination Folder** and
**Bundle Filename**, and the secure-delivery callout names the exact remote path
(`/Commercial_Bank_Sandbox/CVIB_<batch_id>.zip`), resolved from the delivered
`CvibDelivery.remote_path` (fallback: the active connection's `remoteDirectory`).

**A dead mailer is never silent.** SFTP delivery and the email are decoupled — the
transfer can succeed while the mailer fails. Since the operator UI already shows a
successful handover, `#notify` raises a **CRITICAL** `SystemEvent` admin alert on any
mailer exception instead of only logging it.

> **Prod diagnostics** (`lib/capistrano/tasks/diag.rake`, read-only):
> `diag:dispatch_log['<batch_id>']` greps the Sidekiq/Rails logs for a batch's
> delivery+email lines; `diag:gmail_check['<batch_id>']` verifies the OAuth token
> mints and (given a batch) re-sends its notification. Both run server-side via
> `bundle exec ruby -r./config/environment` — this app ships no working
> `bin/rails runner`.

---

## §3 Data Model & Migrations

Two additive, backward-compatible migrations
(`20260821130000`, `20260821130100`), plus the earlier counterparty-credential
migration on `sftps`.

### `sftps` — outbound connection + encrypted credential

The `password` is a **live credential** (needed in plaintext during the SSH
handshake), so it is reversibly encrypted at rest via ActiveRecord Encryption
(`encrypts :password`, AES-256-GCM) — never hashed.

| Column | Type | Purpose |
|---|---|---|
| `hostIPAddress` | string | Remote SFTP host |
| `port` | integer (22) | Remote port |
| `remoteDirectory` | string | Destination directory |
| `username` | string | SFTP login |
| `password` | text | **AES-256-GCM ciphertext** (AR Encryption) |
| `active` | boolean | Enabled for delivery (gated on a passing test) |
| `credential_updated_at` | datetime | Drives the "•••• last updated" display |
| `last_tested_at` / `last_test_ok` | datetime / boolean | Test Connection result |

### `cvib_batches` — recipient identity (A1)

Persisting identity on the batch lets the delivery job resolve destination and
notification context without trusting per-request client params.

| Column | Type | Purpose |
|---|---|---|
| `recipient_swift_code` | string · idx | Destination bank; key into `Sftp.for_delivery` |
| `central_bank_swift` | string | Issuing CB, for the notification |
| `recipient_email` | string | Notification recipient |
| `bank_name` | string | Clean display name (trailing " - SWIFT" stripped) |
| `bundle_filename` | string | Name to write on the remote host |
| `bundle_sha256` | string | Integrity hash of the delivered ZIP |

### `cvib_deliveries` — status ledger

The existing delivery-audit table becomes a state ledger. Existing rows default to
`delivered`; `delivered_at` is now nullable so pending/failed rows can exist before
(or without) a completed transfer.

| Column | Type | Purpose |
|---|---|---|
| `status` | string · idx | Ledger state (see §5); default `delivered` |
| `host` | string | Remote host actually contacted |
| `remote_path` | string | Full remote destination path |
| `bytes` | bigint | Transferred size |
| `error` | text | Failure detail for unresolved rows |
| `delivered_at` | datetime · now null | Set only on success |

---

## §4 API Contract

`POST /api/v2/cvib_batches/:id/upload_bundle` · `multipart/form-data` · Doorkeeper
OAuth2. The batch must be `active`.

### Request

| Field | Req. | Notes |
|---|---|---|
| `bundle` | yes | The packaged ZIP (file part) |
| `bundle_sha256` | yes | Hex SHA-256; server recomputes and must match |
| `recipient_swift_code` | yes | Accepts legacy alias `swift_code` |
| `recipient_email` | rec. | Needed for the success notification |
| `central_bank_swift` | opt. | Persisted on the batch |
| `bank_name` | opt. | Trailing " - SWIFT" stripped for display |

### Success — `200`

```json
{ "error": null,
  "data": {
    "batch_id": "…", "delivery_status": "queued",
    "recipient_swift_code": "BARCGHAC", "bundle_sha256": "…",
    "bundle_filename": "cvib_bundle.zip" } }
```

### Error codes

| HTTP | code | When |
|---|---|---|
| 422 | `batch_not_active` | Batch not yet `active` |
| 422 | `missing_bundle` / `missing_swift` / `missing_bundle_sha256` | Required field absent |
| 422 | `integrity_mismatch` | Computed SHA-256 ≠ declared; spool discarded |
| **409** | `no_sftp_connection` | No active/verified connection — ledger + alert, no fallback |
| 404 | `not_found` | Unknown batch id |

The **409** is significant: it is the per-bank cutover signal. The client treats it
as "this counterparty is not yet provisioned server-side" and falls back to the
legacy `sshpass` path (see §7, §8).

---

## §5 Delivery Ledger & State Machine

Every attempt writes a `CvibDelivery` row (`method: "sftp"`). The job is
**idempotent** — a batch with a `delivered` row is a no-op, so Sidekiq retries
never double-send or double-notify.

| State | Meaning | Retries? | Alerts? |
|---|---|---|---|
| `queued` | Uploaded & enqueued, awaiting the job | — | no |
| `delivered` | Pushed successfully; notification sent | no (terminal) | no |
| `failed` | Transfer error or missing spool | yes — Sidekiq backoff | on exhaustion |
| `pending_no_connection` | No active, verified `Sftp` for the bank | no — hard-fail | **CRITICAL** SystemEvent |

**No silent downgrade.** A missing or inactive connection never falls back to
emailing the bundle as an attachment. It records `pending_no_connection` and raises
a `CRITICAL` `SystemEvent` (source `SFTP`) for the admin console.

---

## §6 Security Controls

The counterparty password is a **live credential** — bearerCORE must present it in
plaintext during the SSH handshake — so it is reversibly encrypted, never hashed.

| Control | Mechanism |
|---|---|
| Encryption at rest | `encrypts :password` — AES-256-GCM (AR Encryption), same scheme as `otp_secret` |
| Write-only | `Sftp#as_json` strips it; the admin form shows `•••• (last updated …)` and never redisplays it |
| Decrypt scope | In-process only — `CvibSftpDeliveryJob` and the Test Connection handshake; never returned to any client |
| Management surface | `/admin/counterparties` — session-authenticated (least privilege), not the shared-token JS console |
| Activation gate | A connection is `active` only after a real `Net::SFTP` handshake passes; any edit resets it |
| Transfer integrity | SHA-256 verified on upload; the ZIP is forwarded as-is (never extracted server-side) |
| Audit trail | Every attempt is a `CvibDelivery` ledger row; `pending_no_connection` / `failed` raise `SystemEvent`s |

Verified against the live database (rolled back): decrypt round-trip matches, the
raw column holds ciphertext not plaintext, serialization strips the field, and the
unreachable-host handshake returns `ok:false` with a clear error.

---

## §7 Desktop Client Scope (`smartcheq_sahara`)

The change is localized to the issuance export path (`sendCvibBundleToBank()`) plus
a new upload primitive on `ApiClient`. The deposit/withdrawal SFTP path
(`withdrawalcbdc.cpp`) is **out of scope here** — tracked as a separate future pass.

| # | Work item | Detail | Status |
|---|---|---|---|
| 1 | `ApiClient::uploadBundle` | Multipart primitive — `QHttpMultiPart` with a streamed `bundle` file part + text parts. Bypasses the JSON `buildRequest` so the boundary Content-Type survives; **parses the v2 envelope even on HTTP 4xx** so a 409 arrives as `error.code`; 120 s timeout. | **done** |
| 2 | `bundle_sha256` | `ApiClient::sha256HexOfFile` — streamed `QCryptographicHash`, safe for large ZIPs. Rails recomputes and rejects on mismatch. | **done** |
| 3 | Replace the SFTP block | In `sendCvibBundleToBank()`, swap the QtConcurrent sshpass upload for `uploadBundle` with `{bundle_sha256, recipient_swift_code, recipient_email, central_bank_swift, bank_name}`. On `200 queued`: archive locally + `confirm_archive`, then stop — the server sends the notification and writes the ledger. | **done** |
| 4 | 409 fallback = per-bank gate | On `409 no_sftp_connection`, fall back to the legacy `sendCvibBundleViaSshpass()`. Banks with a verified connection deliver server-side; others keep the old path until migrated — no flag-day. | **done** |
| 5 | Retire credentials & sshpass | Hide the hand-entered host / dir / user / password fields on the server path; remove them and delete `sftpUploadZip` + the bundled `sshpass` binary once all banks are migrated. | to build |

**Server infra prerequisite.** `upload_bundle` sends the full ZIP over HTTP. The
API host's nginx `client_max_body_size` (default 1 MB) must be raised to the
maximum bundle size before Qt cutover, or uploads fail with `413`.

Recipient identity now lives on the batch — Qt sends it once at `upload_bundle` and
no longer re-supplies `send_bundle_email`, which the job triggers internally. The
move also removes the plaintext password from a shell command (`sshpass -p '…'`)
and from operator workstations entirely.

---

## §8 Counterparty Cutover Protocol

Locked decisions driving the rollout:

- **Identity — A1.** Persisted on `cvib_batches`; the job resolves destination +
  notification context from the batch record.
- **Cutover unit — per-bank.** Routing is gated dynamically on
  `Sftp.for_delivery(swift).present?`. A bank flips to server delivery only once it
  has an active, verified connection.
- **No connection — hard-fail.** `pending_no_connection` + admin alert; never an
  email-attachment fallback.

### Sequence to retire `sshpass`

| Step | Action | Owner |
|---|---|---|
| 1 | Provision + Test-Connection each bank in `/admin/counterparties` | Ops |
| 2 | Ship Qt upload path behind the per-bank gate | Qt |
| 3 | Run one bank end-to-end; confirm `delivered` + notification | Both |
| 4 | Onboard remaining banks as connections are verified | Ops |
| 5 | Remove the `sshpass` path once all banks are migrated | Qt |

**Not yet verifiable end-to-end.** The test database currently holds no batches or
issuance authorizations, so the full push path hasn't been exercised on live data.
First real run is step 3 above.

---

*Server API:* `POST /api/v2/auth/login` and the delivery endpoints follow the
`/api/v2/` namespace with Doorkeeper OAuth2. Credential management is at
`/admin/counterparties` (session-authenticated).
