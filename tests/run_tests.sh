#!/bin/sh
# Unit tests for the re-authentication functions in sync-icloud.sh.
# Run from the repository root: sh tests/run_tests.sh
# Requires GNU/busybox date. On macOS, run it in the image instead:
#   docker run --rm -v "$PWD:/src" -w /src alpine:latest sh tests/run_tests.sh

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
