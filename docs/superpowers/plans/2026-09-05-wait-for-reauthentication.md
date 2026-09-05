# Wait For Re-authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the container cannot authenticate to iCloud, keep it running and send a reminder through the already-configured notification channel once per download interval, instead of exiting and being restarted by Docker forever.

**Architecture:** Introduce one opt-in configuration flag, `wait_for_reauthentication`. When it is set, the three `exit 1` paths in `check_multifactor_authentication_cookie()` stop exiting and instead set a state variable and drop a marker file in `/tmp/icloudpd/`. `synchronise_user()` sees that state, skips the download for this pass, sends one reminder, and falls into the normal inter-download wait — which is where the Telegram polling loop already lives, so `<username> auth` starts working during the outage rather than only outside it. `healthcheck.sh` reports healthy while the marker exists, so autoheal stops restarting a container that a restart cannot fix.

**Tech Stack:** POSIX shell (busybox `ash` in the container, `dash`/`bash` on a dev machine), `curl`, `jq`, `expect`, `inotify-tools`. ShellCheck 0.9+. No test framework — a hand-rolled assertion runner that extracts single functions out of `sync-icloud.sh` with `awk`, consistent with the project's zero-dependency ethos.

**Spec:** This document, § Spec below. The change is small enough that splitting spec and plan across two files would cost more than it buys.

**Branch:** `feature/wait-for-reauthentication`, branched from `fix/telegram-auth-minimal` (which is itself off `master` at `e2d9aa0`). That branch is a prerequisite: it adds the "here is how to re-authenticate" sentence to the expiry warning, and this work extracts that sentence into a function and reuses it. If the upstream PR for `fix/telegram-auth-minimal` is rejected or rewritten, rebase this onto whatever lands and re-run § Manual Verification.

**Line numbers:** all line numbers below are `master` (`e2d9aa0`) unless stated. On the branch, everything after `display_multifactor_authentication_expiry()` is 16 lines lower: `check_files` 822 -> 838, `send_notification` 1884 -> 1900, `synchronise_user` 2246 -> 2262, the Telegram polling loop 2394 -> 2410.

## Global Constraints

- Target shell is busybox `ash`. No bashisms in new code: no `[[ ]]`, no arrays, no `$'...'`. `local` and `${var//x/y}` are permitted — both are used throughout `sync-icloud.sh` already, and both are busybox features. Note `${var//x/y}` is why `dash -n sync-icloud.sh` fails on master; use `bash -n` or `busybox ash -n` for syntax checks.
- `sync-icloud.sh` must gain **no new** ShellCheck codes versus its baseline. The baseline is already noisy, so the gate is "no new codes", not "clean".
- British spelling in user-facing strings ("reinitialise", "synchronisation", "authorised") to match the existing corpus.
- Every user-visible English string needs its `icloud_china=true` Chinese counterpart, matching the existing pattern in `display_multifactor_authentication_expiry()`.
- Telegram messages are sent with `parse_mode=markdown`. New strings must not introduce unescaped `*`, `_`, `[` or backticks. `send_notification` escapes underscores in `${notification_message}` only; keep punctuation plain.
- New configuration variables must be added to `init_config.sh` with `write_variable`, or they will not exist in `/config/icloudpd.conf` for existing installs.
- `build_version.txt` is not touched. The maintainer bumps it himself; touching it would trigger a multi-arch build on merge.
- Run the test suite on Linux or in the image, not on macOS: `docker run --rm -v "$PWD:/src" -w /src alpine:latest sh tests/run_tests.sh`. The code uses GNU/busybox `date -d` syntax, which BSD `date` rejects.
- Default behaviour with the flag unset must be byte-for-byte the behaviour of the parent branch. Every new code path is gated.

---

## Spec

### What happens today

`check_multifactor_authentication_cookie()` (sync-icloud.sh:740) has four ways to fail, three of which end the process:

| Condition | Line | Today |
| --- | --- | --- |
| Cookie file absent | 746 | `wait_for_cookie DisplayMessage` — polls for 30 minutes, then `exit 1` (706) |
| Cookie present, not yet authenticated | 753 | `wait_for_authentication` — polls for 30 minutes, then `exit 1` (722) |
| Cookie expired (`days_remaining` <= 0) | 766-772 | Deletes the cookie, `sleep 300`, `exit 1` |
| Cookie is not MFA-capable | 774-779 | Deletes the cookie, `sleep 300`, `exit 1` |

`sync-icloud.sh` is the container's PID 1 (`launcher.sh` ends with `exec /usr/local/bin/sync-icloud.sh`), so `exit 1` stops the container, and the documented restart policy (`restart: always` in `docker-compose/docker-compose.example.yml`) starts it again.

### The cycle

1. The cookie expires. Pass N of the sync loop hits line 766, deletes the cookie, sleeps 5 minutes, exits.
2. Docker restarts the container. `launcher.sh` re-runs its checks, `sync-icloud.sh` starts, reaches the cookie check — and the cookie is now *absent*, because step 1 deleted it.
3. `wait_for_cookie` polls for 30 minutes, then exits.
4. Go to 2, forever, at roughly one restart every 30 minutes.

If `startup_notification=true`, every one of those restarts also sends a notification.

### The Telegram remote-auth path is dead exactly when it is needed

The polling loop that accepts `<username> auth`, the SMS device letter and the six-digit code lives inside `synchronise_user()`, in the `else` branch of the `single_pass` test (2394-2496) — that is, in the gap *between* downloads. Reaching it requires getting past the cookie check. Once the cookie has expired, that check never passes, so the container never reaches the polling loop, so the remote authentication feature cannot be used to recover from the one failure it exists to recover from. The only remedy today is `docker exec`.

This is the strongest argument for the change, and it is worth leading the pull request with it.

### The second restart driver: healthcheck plus autoheal

`healthcheck.sh` exits non-zero when the cookie file is missing (line 60) or `days_remaining` is below 1 (line 76). `CONFIGURATION.md:455` already documents where that leads:

> Please note, if your MFA cookie expires, the container will be marked as unhealthy, and will be restarted by the authoheal container every five minutes or so... This can lead to a lot of notifications if it happens while you're asleep!

So stopping `sync-icloud.sh` from exiting is only half a fix. For anyone running autoheal, the container is still killed every five minutes. Both drivers have to be addressed together or neither is worth doing.

### What changes

A new configuration flag, `wait_for_reauthentication`, default `false`. When it is `true`:

1. The four failure conditions above set `authentication_required` to a human-readable reason and return, rather than exiting. The cookie file is no longer deleted — `reauth.sh` and the Telegram `auth` handler each delete it themselves before re-authenticating, so deleting it here only destroys the evidence.
2. A marker file, `/tmp/icloudpd/awaiting_reauthentication`, is written containing that reason. `/tmp` does not survive a container restart, which is the correct semantics: a freshly started container is not holding.
3. `synchronise_user()` skips the download for that pass, sends one reminder notification, and enters the normal inter-download wait. Telegram polling therefore runs during the outage, and `<username> auth` works.
4. Each subsequent pass repeats the check. The reminder is throttled to at most one per `reauth_notification_interval`, which defaults to `download_interval` — "on the same schedule it would have backed up", as asked.
5. When a pass finds a valid cookie again, the marker is removed and one "synchronisation resumed" notification is sent.
6. `healthcheck.sh` exits 0 while the marker exists, with a status line naming the reason. Nothing else in the healthcheck changes, and with the flag unset the marker never exists, so its behaviour is unchanged for everyone else.

### Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `wait_for_reauthentication` | `false` | Stay running and remind, instead of exiting, when authentication is required. |
| `reauth_notification_interval` | empty | Seconds between reminders while waiting. Empty means use `download_interval`. |

### Non-goals

- **Download failures that are really auth failures.** If the cookie looks valid but Apple rejects it mid-run, `icloudpd` fails, `send_notification "failure"` already fires each pass (2314), and the script already does not exit. Only the healthcheck restarts it. Detecting "this download error is an auth error" means pattern-matching `icloudpd` error text, which is brittle and belongs in its own change. The common case — the cookie has an expiry date and that date has passed — is caught by the cookie check on the next pass.
- **Missing keyring.** `check_keyring_exists` (661) and `configure_password` (559) have the same 30-minutes-then-exit shape, and a missing keyring cannot be fixed remotely — `authenticate.exp` needs the stored password — so holding buys less. Left alone deliberately; call it out in the pull request as a follow-up.
- **`authentication_type=Web`.** `check_web_cookie()` (727) has the same missing-cookie wait, but it runs after the download rather than before it, and the Web path has no expiry handling to hold on. Left as it is.
- **`check_mount`** (639) also exits after 30 minutes. That is a volume problem, not an auth problem, and a restart plausibly does help. Unchanged.

### Side effects, and what to do about each

1. **The container stops recycling on auth failure.** Anyone watching for restarts or exit codes as their signal that something is wrong loses it. Mitigated by: a log line every pass, a notification every reminder interval, and the flag being off by default.
2. **autoheal stops restarting it** (flag on only). Deliberate. `CONFIGURATION.md:359` and `:455` both describe the current behaviour and must be updated in the same commit as the code.
3. **The expired cookie file survives.** `healthcheck.sh` reads it (line 55) and would compute a negative `days_remaining` — but the marker check returns before that. The Telegram `auth` handler at 2444 does `rm "/config/${cookie_file}" "/config/${cookie_file}.session"` without `-f`, which errors noisily when `.session` is absent. Add `-f` in this change; it is a one-word fix in the path this feature makes reachable.
4. **Telegram polling now runs while unauthenticated.** A `<username>` remote-sync request during a hold breaks the wait and starts a pass that immediately re-enters the hold. That is acceptable behaviour, but `remote_sync_complete_notification` must be unset on the hold path or the user gets a "download complete" that never happened.
5. **`list_albums` and `list_libraries` call `check_multifactor_authentication_cookie` directly** (503, 525). They are one-shot commands, not the sync loop; with the flag on they would now return immediately and run `icloudpd` against a dead cookie. They must fail fast instead — check `authentication_required` and exit 1.
6. **`single_pass=true`** users run this from cron and expect a process that ends. On the hold path they must still exit, and with a non-zero status so cron notices.
7. **`wait_for_cookie` and `wait_for_authentication` become unreachable when the flag is on.** They stay for the flag-off path. Do not delete them.
8. **A fresh, never-initialised install with the flag on** now stays up and notifies every interval instead of exiting every 30 minutes. That is an improvement, but it is a behaviour change worth a sentence in `CONFIGURATION.md`.

## File Structure

- `sync-icloud.sh` — all state and loop changes. Four new functions, one extracted function, one modified function, one modified loop.
- `healthcheck.sh` — five new lines at the top.
- `init_config.sh` — two `write_variable` calls.
- `CONFIGURATION.md` — new variable documentation; corrections to the healthcheck and autoheal sections.
- `change.log` — one dated entry, in the maintainer's voice and format (`DD/MM/YYYY`, then ` - ` bullets).
- `tests/` — new. Not copied into the image (`icloudpd.dockerfile` copies `*.sh` from the root and `authenticate.exp`, nothing else). Each test lands in the same commit as the code it tests; if the maintainer does not want the directory, one commit removes it without touching the rest.

---

## Task 1: Test harness and the re-authentication instruction sentence

The parent branch inlines the "how to re-authenticate" sentence inside `display_multifactor_authentication_expiry()`. The reminder in Task 3 needs the same sentence, so it moves into a function first. Behaviour is unchanged; this is the smallest possible piece of the change and it establishes the test harness everything else uses.

**Files:**
- Create: `tests/run_tests.sh`
- Modify: `sync-icloud.sh` — `display_multifactor_authentication_expiry()` (782-820 on master, 782-836 on the branch)

**Interfaces:**
- Produces: `reauth_instructions()` — no arguments, echoes one line to stdout. Reads globals `notification_type`, `telegram_polling`, `user`, `icloud_china`.
- Produces: `tests/run_tests.sh` with `extract_function <name>` (echoes that function's source from `./sync-icloud.sh` to stdout) and `assert_equals <label> <actual> <expected>`.

- [ ] **Step 1: Write the failing test**

Create `tests/run_tests.sh`:

```sh
#!/bin/sh
# Unit tests for the re-authentication functions in sync-icloud.sh.
# Run from the repository root: sh tests/run_tests.sh

script_under_test="./sync-icloud.sh"
tests_run=0
tests_failed=0

# Echo a single function's source. Relies on the file's convention of a bare
# "name()" line and a closing brace in column 1.
extract_function()
{
   awk -v fn="${1}()" '
      $0 == fn { capture = 1 }
      capture { print }
      capture && $0 == "}" { exit }
   ' "${script_under_test}"
}

assert_equals()
{
   tests_run=$((tests_run + 1))
   if [ "${2}" = "${3}" ]
   then
      printf 'ok   %s\n' "${1}"
   else
      tests_failed=$((tests_failed + 1))
      printf 'FAIL %s\n     expected: %s\n     actual:   %s\n' "${1}" "${3}" "${2}"
   fi
}

##### reauth_instructions #####

eval "$(extract_function reauth_instructions)"

(
   notification_type="telegram"; telegram_polling="true"; user="Josh"; icloud_china="false"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: telegram polling names the reply" \
   "$(cat /tmp/icloudpd_test_out)" \
   "To re-authenticate now, reply to this chat with: Josh auth"

(
   notification_type="telegram"; telegram_polling="false"; user="Josh"; icloud_china="false"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: telegram without polling gives the exec command" \
   "$(cat /tmp/icloudpd_test_out)" \
   "To re-authenticate now, run: docker exec -it <container name> reauth.sh"

(
   notification_type="pushover"; telegram_polling="true"; user="Josh"; icloud_china="false"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: non-telegram gives the exec command" \
   "$(cat /tmp/icloudpd_test_out)" \
   "To re-authenticate now, run: docker exec -it <container name> reauth.sh"

(
   notification_type="telegram"; telegram_polling="true"; user="Josh"; icloud_china="true"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: china variant names the reply" \
   "$(cat /tmp/icloudpd_test_out)" \
   "如需立即重新验证，请在此对话中回复：Josh auth"

rm -f /tmp/icloudpd_test_out

printf '\n%s test(s), %s failure(s)\n' "${tests_run}" "${tests_failed}"
[ "${tests_failed}" -eq 0 ]
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL on all four — `extract_function` finds nothing, so `reauth_instructions` is not a command and each subshell echoes nothing.

- [ ] **Step 3: Add the function and call it from the expiry warning**

Insert immediately above `display_multifactor_authentication_expiry()`:

```sh
reauth_instructions()
{
   if [ "${notification_type}" = "telegram" ] && [ "${telegram_polling}" = "true" ] && [ -n "${user}" ]
   then
      if [ "${icloud_china}" = "false" ]
      then
         echo "To re-authenticate now, reply to this chat with: ${user} auth"
      else
         echo "如需立即重新验证，请在此对话中回复：${user} auth"
      fi
   else
      if [ "${icloud_china}" = "false" ]
      then
         echo "To re-authenticate now, run: docker exec -it <container name> reauth.sh"
      else
         echo "如需立即重新验证，请运行：docker exec -it <容器名称> reauth.sh"
      fi
   fi
}
```

In `display_multifactor_authentication_expiry()`, delete the 16-line `if`/`else` block the parent branch added (the one that assigns `reauth_message`) and replace it with:

```sh
      reauth_message="$(reauth_instructions)"
```

Leave the four `error_message` assignments that interpolate `${reauth_message}` exactly as they are.

- [ ] **Step 4: Run the tests and the syntax check**

Run: `sh tests/run_tests.sh`
Expected: `4 test(s), 0 failure(s)`

Run: `bash -n sync-icloud.sh && shellcheck -S warning sync-icloud.sh | grep -c '^In'`
Expected: no syntax error; the finding count is unchanged from the count recorded before the edit (record it first with `git stash`).

- [ ] **Step 5: Commit**

```bash
git add tests/run_tests.sh sync-icloud.sh
git commit -m "Move the re-authentication instructions into their own function

The expiry warning is about to stop being the only place that needs to
tell the user how to re-authenticate."
```

---

## Task 2: The hold state

Two functions that own the `authentication_required` variable and the marker file that `healthcheck.sh` will read. Nothing calls them yet.

**Files:**
- Modify: `sync-icloud.sh` — new functions, inserted after `reauth_instructions()`
- Modify: `tests/run_tests.sh`

**Interfaces:**
- Consumes: `reauth_instructions()` from Task 1 (not yet — Task 3 uses it).
- Produces: `require_reauthentication <reason>` — sets `authentication_required` to `<reason>`, writes `<reason>` to `${reauth_marker_file:=/tmp/icloudpd/awaiting_reauthentication}`, logs. Idempotent.
- Produces: `clear_reauthentication_hold` — removes the marker if present, sends one "resumed" notification if and only if the marker was present, unsets `authentication_required` and `next_reauth_notification_time`. Safe to call on every successful pass.
- The marker path is `${reauth_marker_file}` with a `:=` default, so tests can point it somewhere else. `healthcheck.sh` hardcodes the same literal path.

- [ ] **Step 1: Write the failing test**

Append to `tests/run_tests.sh`, before the final `printf`:

```sh
##### require_reauthentication / clear_reauthentication_hold #####

eval "$(extract_function require_reauthentication)"
eval "$(extract_function clear_reauthentication_hold)"

log_error() { :; }
log_info() { :; }
log_debug() { :; }
send_notification() { echo "notified:${1}" >> "${notifications_sent}"; }

reauth_marker_file="/tmp/icloudpd_test_marker"
notifications_sent="/tmp/icloudpd_test_notifications"
rm -f "${reauth_marker_file}" "${notifications_sent}"
: > "${notifications_sent}"

require_reauthentication "Cookie expired at: yesterday"
assert_equals "require_reauthentication: writes the marker" \
   "$(cat "${reauth_marker_file}")" \
   "Cookie expired at: yesterday"
assert_equals "require_reauthentication: sets the state variable" \
   "${authentication_required}" \
   "Cookie expired at: yesterday"

require_reauthentication "Cookie expired at: yesterday"
assert_equals "require_reauthentication: is idempotent" \
   "$(wc -l < "${reauth_marker_file}" | tr -d ' ')" \
   "1"

clear_reauthentication_hold
assert_equals "clear_reauthentication_hold: removes the marker" \
   "$([ -f "${reauth_marker_file}" ] && echo present || echo absent)" \
   "absent"
assert_equals "clear_reauthentication_hold: clears the state variable" \
   "${authentication_required:-empty}" \
   "empty"
assert_equals "clear_reauthentication_hold: notifies once on recovery" \
   "$(cat "${notifications_sent}")" \
   "notified:startup"

: > "${notifications_sent}"
clear_reauthentication_hold
assert_equals "clear_reauthentication_hold: silent when not holding" \
   "$(cat "${notifications_sent}")" \
   ""

rm -f "${reauth_marker_file}" "${notifications_sent}"
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `sh tests/run_tests.sh`
Expected: the four `reauth_instructions` tests still pass; the new ones fail because neither function exists.

- [ ] **Step 3: Add the functions**

Insert after `reauth_instructions()`:

```sh
require_reauthentication()
{
   local reason
   reason="${1}"
   authentication_required="${reason}"
   mkdir -p "$(dirname "${reauth_marker_file:=/tmp/icloudpd/awaiting_reauthentication}")"
   printf '%s\n' "${reason}" > "${reauth_marker_file}"
   log_error "${reason}"
   log_error " - Downloads are paused. The container will stay running and remind you until re-authentication is complete"
   log_error " - $(reauth_instructions)"
}

clear_reauthentication_hold()
{
   if [ -f "${reauth_marker_file:=/tmp/icloudpd/awaiting_reauthentication}" ]
   then
      rm -f "${reauth_marker_file}"
      log_info "Re-authentication complete. Resuming synchronisation"
      if [ "${icloud_china}" = "false" ]
      then
         send_notification "startup" "iCloudPD authentication restored" "0" "Re-authentication complete for Apple ID: ${apple_id}. Synchronisation has resumed"
      else
         send_notification "startup" "iCloudPD authentication restored" "0" "${name} 的 Apple ID 重新验证成功，同步已恢复" "" "" "" "${name} 的 iCloud 图库同步已恢复" "Apple ID: ${apple_id}"
      fi
   fi
   unset authentication_required next_reauth_notification_time
}
```

Note the marker's parent directory: `/tmp/icloudpd` is created by `launcher.sh` before `sync-icloud.sh` runs, but `mkdir -p` costs nothing and makes the function testable in isolation.

- [ ] **Step 4: Run the tests**

Run: `sh tests/run_tests.sh`
Expected: `11 test(s), 0 failure(s)`

Run: `bash -n sync-icloud.sh`
Expected: silent.

- [ ] **Step 5: Commit**

```bash
git add tests/run_tests.sh sync-icloud.sh
git commit -m "Add the re-authentication hold state and its marker file

Nothing sets the hold yet. The marker lives in /tmp so that it does not
survive a container restart, which is the behaviour we want: a container
that has just started is not waiting for anything."
```

---

## Task 3: The periodic reminder

**Files:**
- Modify: `sync-icloud.sh` — new function after `clear_reauthentication_hold()`
- Modify: `tests/run_tests.sh`

**Interfaces:**
- Consumes: `reauth_instructions()`, `authentication_required`, globals `apple_id`, `download_interval`, `icloud_china`, `name`.
- Produces: `reauthentication_reminder` — sends at most one notification per `${reauth_notification_interval:-${download_interval}}` seconds, and sets `next_reauth_notification_time` to the next permitted time. Sends on the first call after a hold begins, because `clear_reauthentication_hold` unsets `next_reauth_notification_time` and the function treats unset as zero.

- [ ] **Step 1: Write the failing test**

Append to `tests/run_tests.sh`, before the final `printf`:

```sh
##### reauthentication_reminder #####

eval "$(extract_function reauthentication_reminder)"

log_warning() { :; }
send_notification() { printf '%s|%s\n' "${1}" "${4}" >> "${notifications_sent}"; }

notifications_sent="/tmp/icloudpd_test_notifications"
: > "${notifications_sent}"
apple_id="someone@example.com"
icloud_china="false"
notification_type="telegram"
telegram_polling="true"
user="Josh"
download_interval=86400
unset reauth_notification_interval next_reauth_notification_time
authentication_required="Cookie expired at: yesterday"

reauthentication_reminder
assert_equals "reauthentication_reminder: sends on the first pass" \
   "$(wc -l < "${notifications_sent}" | tr -d ' ')" \
   "1"
assert_equals "reauthentication_reminder: classified as cookie expired" \
   "$(cut -d'|' -f1 < "${notifications_sent}")" \
   "cookie expired"
assert_equals "reauthentication_reminder: message carries reason and instructions" \
   "$(cut -d'|' -f2 < "${notifications_sent}")" \
   "Authentication required for Apple ID: someone@example.com - Cookie expired at: yesterday. Downloads are paused until this is resolved. To re-authenticate now, reply to this chat with: Josh auth"

reauthentication_reminder
assert_equals "reauthentication_reminder: throttled on the next pass" \
   "$(wc -l < "${notifications_sent}" | tr -d ' ')" \
   "1"

next_reauth_notification_time=1
reauthentication_reminder
assert_equals "reauthentication_reminder: sends again once the interval has passed" \
   "$(wc -l < "${notifications_sent}" | tr -d ' ')" \
   "2"

reauth_notification_interval=3600
next_reauth_notification_time=1
reauthentication_reminder
assert_equals "reauthentication_reminder: override sets the next time an hour out" \
   "$(( next_reauth_notification_time - $(date +%s) > 3500 && next_reauth_notification_time - $(date +%s) <= 3600 ))" \
   "1"

rm -f "${notifications_sent}"
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `sh tests/run_tests.sh`
Expected: the eleven earlier tests pass, the six new ones fail — `reauthentication_reminder: not found`.

- [ ] **Step 3: Add the function**

Insert after `clear_reauthentication_hold()`:

```sh
reauthentication_reminder()
{
   local reminder_interval reminder_message
   reminder_interval="${reauth_notification_interval:-${download_interval}}"
   if [ "${icloud_china}" = "false" ]
   then
      reminder_message="Authentication required for Apple ID: ${apple_id} - ${authentication_required}. Downloads are paused until this is resolved. $(reauth_instructions)"
   else
      reminder_message="${name} 的 Apple ID 需要重新验证 - ${authentication_required}。下载已暂停。$(reauth_instructions)"
   fi
   log_warning "${reminder_message}"
   if [ "$(date +%s)" -ge "${next_reauth_notification_time:=0}" ]
   then
      if [ "${icloud_china}" = "false" ]
      then
         send_notification "cookie expired" "iCloudPD authentication required" "1" "${reminder_message}"
      else
         send_notification "cookie expired" "iCloudPD authentication required" "1" "${reminder_message}" "" "" "" "${name} 的 iCloud 需要重新验证" "${reminder_message}"
      fi
      next_reauth_notification_time="$(date +%s -d "+${reminder_interval} seconds")"
      log_debug "Next re-authentication reminder not before: $(date +%c -d "@${next_reauth_notification_time}")"
   fi
}
```

The `cookie expired` classification is not new — `send_notification` (1927) already maps it to the 🚨 icon and the warning image, which is what this is.

- [ ] **Step 4: Run the tests**

Run: `sh tests/run_tests.sh`
Expected: `17 test(s), 0 failure(s)`

- [ ] **Step 5: Commit**

```bash
git add tests/run_tests.sh sync-icloud.sh
git commit -m "Add the periodic re-authentication reminder

One notification per download interval by default, through whichever
channel is already configured. reauth_notification_interval overrides the
cadence for anyone syncing more often than they want to be nagged."
```

---

## Task 4: Extract the inter-download wait

The Telegram polling loop is 106 lines buried in the middle of `synchronise_user()`. The hold path needs to run exactly that loop — that is the whole point, since it is what makes `<username> auth` reachable during an outage — so it becomes a function. No behaviour change; the test is that the moved code is identical.

**Files:**
- Modify: `sync-icloud.sh` — `synchronise_user()` lines 2391-2496 on master, 2407-2512 on the branch

**Interfaces:**
- Produces: `wait_for_next_download <seconds>` — polls Telegram for remote commands for `<seconds>` if `notification_type=telegram` and `telegram_polling=true`, otherwise sleeps for `<seconds>`. Returns early when a remote sync is requested. Reads and writes the same globals the inline code did: `listen_counter`, `poll_sleep`, `latest_updates`, `latest_update_ids`, `break_while`, `update_count`, `telegram_update_id_offset`, `remote_sync_complete_notification`.

- [ ] **Step 1: Record the before-image**

```bash
sed -n '2407,2512p' sync-icloud.sh | sed 's/^ *//' > /tmp/wait_before.txt
wc -l /tmp/wait_before.txt   # expect 106
```

- [ ] **Step 2: Move the block into a function**

Cut lines 2407-2512 (branch numbering) out of `synchronise_user()` and paste them as the body of a new function inserted immediately before `synchronise_user()`:

```sh
wait_for_next_download()
{
   local sleep_time
   sleep_time="${1}"
   if [ "${notification_type}" = "telegram" ] && [ "${telegram_polling}" = "true" ]
   then
      ... the 106 moved lines, dedented by three spaces ...
   else
      sleep "${sleep_time}"
   fi
}
```

In `synchronise_user()`, replace the removed block with:

```sh
         wait_for_next_download "${sleep_time}"
```

Both `break` statements inside the moved code target the inner `while [ "${listen_counter}" -lt "${sleep_time}" ]` loop, not the outer `while true`, so moving them into a function does not change what they break out of. Verify this by eye before running anything: the expect-error `break` at the top of the loop and the remote-sync `break` near the bottom are both inside that inner `while`/`done` pair.

- [ ] **Step 3: Prove the move was faithful**

```bash
sed -n '/^wait_for_next_download()/,/^}/p' sync-icloud.sh \
   | sed '1,4d;$d' | sed 's/^ *//' > /tmp/wait_after.txt
diff /tmp/wait_before.txt /tmp/wait_after.txt
```

Expected: no output. If the dedent was done with an editor's block-shift the leading whitespace differs, which `sed 's/^ *//'` removes; anything else `diff` reports is a real change and must be reverted.

- [ ] **Step 4: Syntax and lint**

Run: `bash -n sync-icloud.sh && shellcheck -S warning sync-icloud.sh | grep '^In' | wc -l`
Expected: no syntax error, finding count unchanged.

Run: `sh tests/run_tests.sh`
Expected: `17 test(s), 0 failure(s)` — unchanged, this task adds no tested behaviour.

- [ ] **Step 5: Commit**

```bash
git add sync-icloud.sh
git commit -m "Extract the inter-download wait into a function

Pure move. The next commit needs to run this loop from a second place:
while the container is waiting to be re-authenticated, which is exactly
when the remote auth command it listens for is most useful."
```

---

## Task 5: Hold instead of exiting

**Files:**
- Modify: `sync-icloud.sh` — `check_multifactor_authentication_cookie()` (740-780)

**Interfaces:**
- Consumes: `require_reauthentication`, `clear_reauthentication_hold`, the new `wait_for_reauthentication` flag.
- Produces: `check_multifactor_authentication_cookie()` may now return with `authentication_required` set and `valid_mfa_cookie` still `false`. Every caller must handle that — see Task 6.

`authentication_type=Web` is out of scope. `check_web_cookie()` keeps its 30-minute wait: it runs after the download rather than before it, so holding on it would need a second, differently-shaped hold, and the Web path has no expiry handling to hold on in the first place.

- [ ] **Step 1: Gate the missing-cookie path**

In `check_multifactor_authentication_cookie()`, in the `else` branch of the file-exists test, insert before `wait_for_cookie DisplayMessage`:

```sh
      if [ "${wait_for_reauthentication}" = "true" ]
      then
         require_reauthentication "Multi-factor authentication cookie does not exist for Apple ID: ${apple_id}"
         return
      fi
```

- [ ] **Step 2: Gate the not-yet-authenticated path**

Insert before `wait_for_authentication`:

```sh
      if [ "${wait_for_reauthentication}" = "true" ]
      then
         require_reauthentication "Multi-factor authentication has not been completed for Apple ID: ${apple_id}"
         return
      fi
```

- [ ] **Step 3: Gate the two exit paths, and clear the hold on success**

Replace the `days_remaining` block with:

```sh
      if [ "${days_remaining}" -gt 0 ]
      then
         valid_mfa_cookie=true
         clear_reauthentication_hold
         log_debug "Valid multi-factor authentication cookie found. Days until expiration: ${days_remaining}"
      else
         if [ "${wait_for_reauthentication}" = "true" ]
         then
            require_reauthentication "Multi-factor authentication cookie for Apple ID: ${apple_id} expired at: ${mfa_expire_date}"
            return
         fi
         rm -f "/config/${cookie_file}"
         log_error "Cookie expired at: ${mfa_expire_date}"
         log_error "Expired cookie file has been removed. Restarting container in 5 minutes"
         sleep 300
         exit 1
      fi
   else
      if [ "${wait_for_reauthentication}" = "true" ]
      then
         require_reauthentication "Cookie for Apple ID: ${apple_id} is not multi-factor authentication capable. The authentication type may have changed"
         return
      fi
      rm -f "/config/${cookie_file}"
      log_error "Cookie is not multi-factor authentication capable, authentication type may have changed"
      log_error "Invalid cookie file has been removed. Restarting container in 5 minutes"
      sleep 300
      exit 1
   fi
```

Two deliberate choices here. The cookie file is **not** deleted on the hold path: `reauth.sh` and the Telegram `auth` handler both delete it themselves before re-authenticating, so deleting it here only removes the expiry date from the log and from `healthcheck.sh`. And `clear_reauthentication_hold` is called unconditionally on success rather than behind the flag — with the flag off no marker can exist, so it is a no-op, and gating it would add a branch that can never be false in one direction.

- [ ] **Step 4: Guard the caller loop**

In `synchronise_user()`, the loop that calls this function spins forever if the cookie never becomes valid:

```sh
         while [ "${valid_mfa_cookie}" = "false" ]
```

becomes

```sh
         while [ "${valid_mfa_cookie}" = "false" ] && [ -z "${authentication_required}" ]
```

- [ ] **Step 5: Make the one-shot commands fail fast**

`list_libraries()` (498) and `list_albums()` (520) call this function directly and are not the sync loop. In each, immediately after the `check_multifactor_authentication_cookie` call, add:

```sh
   if [ -n "${authentication_required}" ]
   then
      log_error "Cannot list: authentication is required. $(reauth_instructions)"
      exit 1
   fi
```

- [ ] **Step 6: Syntax, lint, tests**

Run: `bash -n sync-icloud.sh && shellcheck -S warning sync-icloud.sh | grep '^In' | wc -l && sh tests/run_tests.sh`
Expected: no syntax error, finding count unchanged, `17 test(s), 0 failure(s)`.

- [ ] **Step 7: Commit**

```bash
git add sync-icloud.sh
git commit -m "Hold for re-authentication instead of exiting the container

With wait_for_reauthentication=true, the four dead ends in the MFA cookie
check record why they are stuck and return, rather than deleting the
cookie and killing the container for Docker to restart. The one-shot list
commands still fail fast, because there is nobody there to be reminded."
```

---

## Task 6: Wire the hold into the sync loop

**Files:**
- Modify: `sync-icloud.sh` — `synchronise_user()`

- [ ] **Step 1: Reset the state at the top of each pass**

Immediately after `download_time="$(date +%s -d '+15 minutes')"`, add:

```sh
      unset authentication_required
```

- [ ] **Step 2: Add the hold branch**

Immediately after the `while [ "${valid_mfa_cookie}" = "false" ] ... done` loop and its closing `fi`, and before `check_mount`, insert:

```sh
      if [ -n "${authentication_required}" ]
      then
         reauthentication_reminder
         unset remote_sync_complete_notification
         if [ "${single_pass:-false}" = "true" ]
         then
            log_error "Single Pass mode set and authentication is required, exiting"
            exit 1
         fi
         download_end_time="$(date +'%s')"
         sleep_time="$((download_interval - download_end_time + download_start_time))"
         log_info "Next authentication check at $(date +%H:%M:%S -d "${sleep_time} seconds")"
         wait_for_next_download "${sleep_time}"
         continue
      fi
```

`unset remote_sync_complete_notification` matters: a `<username>` remote-sync request that arrives during a hold breaks the wait and starts a pass that immediately re-enters the hold. Without the unset, the user gets a "remote download complete" notification for a download that never ran.

`exit 1` rather than `exit 0` for `single_pass`: these are cron users, and a silent success would hide the outage.

- [ ] **Step 3: Fix the unguarded rm in the Telegram auth handler**

In `wait_for_next_download()`, the `auth` branch (moved in Task 4) does:

```sh
			                     rm "/config/${cookie_file}" "/config/${cookie_file}.session"
```

Change `rm` to `rm -f`. This path is now reachable when the cookie or session file is absent — which is precisely the case this feature creates — and `rm` without `-f` writes to stderr and returns non-zero for each missing file. (Leave the file's existing stray tab indentation alone; fixing it would bury a one-word change in a whitespace diff.)

- [ ] **Step 4: Trace the loop by hand**

Read the modified `synchronise_user()` top to bottom and confirm all four hold-path invariants:

1. With the flag off, `authentication_required` is never set, so the branch never runs and every line executes in its original order.
2. With the flag on and a valid cookie, `clear_reauthentication_hold` runs and the branch is skipped.
3. With the flag on and an invalid cookie, `check_mount`, `check_files`, the download block, `check_web_cookie`, `display_multifactor_authentication_expiry` and the `login_counter` increment are all skipped, and the pass ends in `wait_for_next_download`.
4. `sleep_time` on the hold path is computed the same way as on the normal path, so a hold pass takes one `download_interval`, not zero.

- [ ] **Step 5: Syntax, lint, tests**

Run: `bash -n sync-icloud.sh && shellcheck -S warning sync-icloud.sh | grep '^In' | wc -l && sh tests/run_tests.sh`
Expected: no syntax error, finding count unchanged, `17 test(s), 0 failure(s)`.

- [ ] **Step 6: Commit**

```bash
git add sync-icloud.sh
git commit -m "Skip the download and remind, while waiting to be re-authenticated

The pass ends in the same wait as a successful one, so Telegram polling
runs during the outage and '<username> auth' now works when it is needed
rather than only when it is not."
```

---

## Task 7: Stop autoheal restarting a container that is deliberately waiting

**Files:**
- Modify: `healthcheck.sh`

- [ ] **Step 1: Add the marker check**

Immediately after `source "/config/icloudpd.conf"`, before the exit-code file checks, insert:

```sh
if [ -f "/tmp/icloudpd/awaiting_reauthentication" ]
then
   echo "Awaiting re-authentication: $(cat /tmp/icloudpd/awaiting_reauthentication)"
   exit 0
fi
```

It has to be first. On a hold pass no download runs, so `/tmp/icloudpd/icloudpd_download_exit_code` may be stale or absent, and the "Error check files missing" branch would exit 1 before ever reaching the cookie tests.

The marker only exists when `wait_for_reauthentication=true`, so nothing changes for anyone else.

- [ ] **Step 2: Lint**

Run: `bash -n healthcheck.sh && shellcheck -S warning healthcheck.sh`
Expected: no new findings.

- [ ] **Step 3: Verify by hand, in the container**

There is no unit test for this one — `healthcheck.sh` sources `/config/icloudpd.conf` from an absolute path, so it only runs meaningfully inside the image. Covered by § Manual Verification, step 5.

- [ ] **Step 4: Commit**

```bash
git add healthcheck.sh
git commit -m "Report healthy while deliberately waiting for re-authentication

A restart cannot produce an MFA code, so a container that is waiting for
one should not ask to be restarted. Only reachable with
wait_for_reauthentication=true."
```

---

## Task 8: Configuration and documentation

**Files:**
- Modify: `init_config.sh`, `CONFIGURATION.md`, `change.log`

- [ ] **Step 1: Add the variables**

In `init_config.sh`, in the alphabetically-ordered `write_variable` block:

```sh
write_variable reauth_notification_interval
write_variable wait_for_reauthentication false
```

`reauth_notification_interval` gets no default, so it lands as an empty value and `reauthentication_reminder` falls back to `download_interval`.

- [ ] **Step 2: Document the variables**

In `CONFIGURATION.md`, next to `notification_days` (line 28) and in alphabetical position:

```markdown
**wait_for_reauthentication**: Set this to **true** and the container will stay running when it needs to be re-authenticated, instead of exiting and being restarted by Docker over and over. Downloads pause, and a reminder is sent through your configured notification method once per download_interval until you re-authenticate. If you use Telegram with telegram_polling enabled, this also means the container is listening for your **&lt;user name&gt; auth** reply while it is waiting - with the default behaviour it is not, because it never gets that far. While the container is waiting, the health check reports healthy, so autoheal will leave it alone. Default: false.

**reauth_notification_interval**: The number of seconds between re-authentication reminders. Only used when wait_for_reauthentication is true. Default: the value of download_interval.
```

- [ ] **Step 3: Correct the health check sections**

`CONFIGURATION.md:359` and `:455` both describe the current unhealthy-on-expiry behaviour. Append to each:

Line 359, after the existing sentence: `Unless wait_for_reauthentication is set, in which case the container reports healthy while it waits for you to re-authenticate.`

Line 455, after the "This can lead to a lot of notifications if it happens while you're asleep!" sentence: `Setting wait_for_reauthentication=true avoids this: the container stays up, reports healthy, and reminds you once per download_interval instead.`

- [ ] **Step 4: Log the change**

Prepend to `change.log`, matching the file's `DD/MM/YYYY` heading and ` - ` bullet style:

```
05/09/2026

 - Added wait_for_reauthentication. When it's set, an expired or missing cookie no longer kills the container and leaves Docker to restart it every half hour. It stays up, pauses downloads, and reminds you through whatever notification method you've configured, once per download_interval. Reminder cadence can be overridden with reauth_notification_interval
 - Side effect worth knowing about: while it's waiting, the health check reports healthy, so autoheal won't restart it. Nothing a restart can do would fix a missing MFA code anyway
 - The Telegram polling loop now runs while the container is unauthenticated, so "<user> auth" actually works during an outage. Previously the container never reached the polling loop once the cookie had expired, which is the one time you'd want it
```

- [ ] **Step 5: Verify**

Run: `bash -n init_config.sh && shellcheck -S warning init_config.sh`
Expected: no new findings.

Confirm `git diff --stat` for this commit touches only the three files, and that `build_version.txt` is not among them.

- [ ] **Step 6: Commit**

```bash
git add init_config.sh CONFIGURATION.md change.log
git commit -m "Document wait_for_reauthentication and log the change"
```

---

## Task 9: Manual verification

Nothing above proves the container behaves correctly, only that the pieces do. This task is the evidence for the pull request; run it before opening one, and paste the log excerpts into the PR body.

**Files:** none. This task produces `/tmp/icloudpd-verification.md` — a transcript to quote from.

- [ ] **Step 1: Build the image**

```bash
docker build -f icloudpd.dockerfile -t icloudpd-verify .
```

- [ ] **Step 2: Make a config and an already-expired cookie**

```bash
mkdir -p /tmp/icloudpd-verify/config /tmp/icloudpd-verify/photos
touch /tmp/icloudpd-verify/photos/.mounted
mkdir -p /tmp/icloudpd-verify/config/python_keyring
printf '[icloudpd]\nverify%%40example.com = fake\n' > /tmp/icloudpd-verify/config/python_keyring/keyring_pass.cfg
cat > /tmp/icloudpd-verify/config/verifyexamplecom <<'COOKIE'
#LWP-Cookies-2.0
Set-Cookie3: X-APPLE-WEBAUTH-USER="v=1"; path="/"; domain=".icloud.com"; path_spec; domain_dot; secure; expires="2020-01-01 00:00:00Z"; HttpOnly
Set-Cookie3: X-APPLE-WEBAUTH-HSA-TRUST="v=1"; path="/"; domain=".icloud.com"; path_spec; domain_dot; secure; expires="2020-01-01 00:00:00Z"; HttpOnly
Set-Cookie3: X-APPLE-DS-WEB-SESSION-TOKEN="v=1"; path="/"; domain=".icloud.com"; path_spec; domain_dot; secure; expires="2020-01-01 00:00:00Z"; HttpOnly
Set-Cookie3: X_APPLE_WEB_KB="v=1"; path="/"; domain=".icloud.com"; path_spec; domain_dot; secure; expires="2030-01-01 00:00:00Z"; HttpOnly
COOKIE
```

The cookie file's name is the Apple ID with everything but `[a-z0-9_]` stripped (`initialise_script`, line 26). Only the `grep -c` counts and the `expires=` dates matter here; the values are ignored.

- [ ] **Step 3: Confirm the old behaviour is unchanged with the flag off**

```bash
docker run --rm --name icloudpd-verify \
   -e apple_id=verify@example.com -e user=verify -e download_interval=120 \
   -v /tmp/icloudpd-verify/config:/config \
   -v /tmp/icloudpd-verify/photos:/home/verify/iCloud \
   icloudpd-verify
```

Expected: `ERROR Cookie expired at: 2020-01-01 00:00:00`, then `Expired cookie file has been removed. Restarting container in 5 minutes`, then the container stops. Confirm the cookie file is gone from `/tmp/icloudpd-verify/config`. Then restore it from Step 2 for the next run.

- [ ] **Step 4: Confirm the hold**

Same command plus `-e wait_for_reauthentication=true`, and `--restart no` so a mistake cannot loop.

Expected, within the first minute:

```
ERROR    Multi-factor authentication cookie for Apple ID: verify@example.com expired at: 2020-01-01 00:00:00
ERROR     - Downloads are paused. The container will stay running and remind you until re-authentication is complete
ERROR     - To re-authenticate now, run: docker exec -it <container name> reauth.sh
WARNING  Authentication required for Apple ID: verify@example.com - ...
INFO     Next authentication check at HH:MM:SS
```

Then, 120 seconds later, the same `WARNING` again — and no restart in between. Confirm with `docker ps` that uptime is continuous, and that the cookie file still exists.

- [ ] **Step 5: Confirm the health status**

While the container from Step 4 is holding:

```bash
docker inspect --format '{{.State.Health.Status}}' icloudpd-verify
docker inspect --format '{{json .State.Health.Log}}' icloudpd-verify | tail -c 400
```

Expected: `healthy`, and a log entry reading `Awaiting re-authentication: Multi-factor authentication cookie for Apple ID: verify@example.com expired at: 2020-01-01 00:00:00`.

- [ ] **Step 6: Confirm recovery**

While it holds, replace the cookie with one that expires in the future:

```bash
sed -i 's/2020-01-01/2030-01-01/g' /tmp/icloudpd-verify/config/verifyexamplecom
```

Expected on the next pass: `INFO Re-authentication complete. Resuming synchronisation`, the marker gone (`docker exec icloudpd-verify ls /tmp/icloudpd/`), and the normal download attempt resuming (it will fail against a fake Apple ID — that is fine, the point is that it tried).

- [ ] **Step 7: Confirm the headline claim, end to end**

This one needs a real Telegram bot and a real Apple ID, so run it against your own container rather than the fake one. With `wait_for_reauthentication=true`, `notification_type=telegram` and `telegram_polling=true`, force a hold by moving the cookie aside:

```bash
docker exec <container> sh -c 'mv /config/<cookie> /config/<cookie>.heldtest'
```

Expected: a reminder arrives naming the `<user name> auth` reply; sending that reply from the phone starts `authenticate.exp`; the MFA code arrives; authentication completes; the resumed notification arrives. This is the behaviour that is impossible on `master`, and it is what the pull request is asking the maintainer to believe.

- [ ] **Step 8: Record it**

Save the log excerpts from Steps 3-7 to `/tmp/icloudpd-verification.md`. They become the "how this was tested" section of the pull request. Nothing gets committed in this task.

---

## Open Questions for the maintainer

Raise these in the pull request rather than deciding them unilaterally.

1. **Should the default flip?** The change ships opt-out-shaped but defaults to off, so no existing install changes behaviour. The argument for defaulting to `true` is that `CONFIGURATION.md:455` already documents the current behaviour as an annoyance. The argument against is that some people watch for container restarts. Happy to flip the default in a follow-up.
2. **Is the health check change acceptable?** It is the part that touches documented behaviour. The reasoning: a restart cannot produce an MFA code, so a container waiting for one should not ask to be restarted. If preferred, the container can stay unhealthy and the flag can cover only the exit behaviour — but then autoheal users get no benefit.
3. **Keyring and mount failures have the same shape.** Both wait 30 minutes and exit. Neither is included here. Worth the same treatment, in a separate change?
4. **`authentication_type=Web`** is untouched. Nobody appears to use it, and its cookie check runs after the download rather than before it. Confirm it can stay as it is.
5. **Does `tests/` belong in the repository?** It is one file, not copied into the image, and it exists because the last pull request's functions were worth testing. Say the word and the directory comes out; the code commits do not depend on it.

## Notes for the pull request body

Lead with the Telegram point, not the restart loop. "Your remote authentication feature cannot be used to recover from the failure it exists to recover from, because the container never reaches the polling loop once the cookie has expired" is a specific, checkable claim about his code. "The container restarts a lot" is a complaint.

Then: the flag is off by default, `build_version.txt` is untouched so no build is triggered on merge, ShellCheck gains no new findings, and Steps 3-7 above are the evidence.
