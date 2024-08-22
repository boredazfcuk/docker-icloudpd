#!/bin/ash

send_message(){
   local text
   text="$1"
   notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
      --data chat_id="${telegram_chat_id}" \
      --data parse_mode="markdown" \
      --data disable_notification="${telegram_disable_notification:=false}" \
      --data text="${text}")"
}

choose_sms_number(){
   local auth_log_numbers auth_log_text
   auth_log_numbers="$(grep "^ " /tmp/icloudpd/reauth.log | sed 's/\*\*\*\*\*\*\*\*/number ending in /g')"
   auth_log_text="Please select option to send the SMS code to:%0A${auth_log_numbers}%0AReply with '${user} <option>' to select the number, or reply with '${user} <mfa code>' to use an Apple iDevice MFA code"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${auth_log_text}")"
}

request_mfa_code(){
   local request_mfa_text
   request_mfa_text="Please reply with ${user} <6-digit code> in the next 10mins"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${request_mfa_text}")"
}

mfa_success(){
   local mfa_success_text
   mfa_success_text="MFA successfully re-confirmed for ${user}"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${mfa_success_text}")"
}

mfa_failure(){
   local mfa_failure_text
   mfa_failure_text="MFA failed for ${user}. Please try again"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${mfa_failure_text}")"
}

config_file="/config/icloudpd.conf"
user="$(grep "^user=" ${config_file} | awk -F= '{print $2}')"
apple_id="$(grep "^apple_id=" ${config_file} | awk -F= '{print $2}')"
telegram_chat_id="$(grep "^telegram_chat_id=" ${config_file} | awk -F= '{print $2}')"
telegram_server="$(grep "^telegram_server=" ${config_file} | awk -F= '{print $2}')"
telegram_token="$(grep "^telegram_token=" ${config_file} | awk -F= '{print $2}')"
notification_title="$(grep "^notification_title=" ${config_file} | awk -F= '{print $2}')"
notification_icon="\xE2\x96\xB6"

if [ "${notification_title}" ]; then
   notification_title="${notification_title//[^a-zA-Z0-9_ ]/}"
else
   notification_title="boredazfcuk/iCloudPD"
fi

if [ "${telegram_server}" ] ; then
   notification_url="https://${telegram_server}/bot${telegram_token}/sendMessage"
else
   notification_url="https://api.telegram.org/bot${telegram_token}/sendMessage"
fi

if [ "$1" = "smschoice" ]; then
   choose_sms_number
elif [ "$1" = "mfacode" ]; then
   request_mfa_code
elif [ "$1" = "success" ]; then
   mfa_success
elif [ "$1" = "failure" ]; then
   mfa_failure
fi