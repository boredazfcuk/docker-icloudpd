#!/bin/ash

send_message()
{
   local text
   text="$1"
   notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
      --data chat_id="${telegram_chat_id}" \
      --data parse_mode="markdown" \
      --data disable_notification="${telegram_disable_notification:=false}" \
      --data text="${text}")"
}

choose_sms_number()
{
   local auth_log_numbers auth_log_text
   auth_log_numbers="$(grep "^ " /tmp/icloudpd/reauth.log | sed 's/\*\*\*\*\*\ \*\*\*\*/number ending in /g')"
   auth_index_upper="$(grep "^ " /tmp/icloudpd/reauth.log | tail -1 | awk -F: '{print $1}' | sed 's/ //g')"
   if [ "${auth_index_upper}" = "a" ]
   then
      option_list="a"
   else
      option_list="a-${auth_index_upper}"
   fi
   auth_log_text="Please select option to send the SMS code to:%0A${auth_log_numbers}%0AReply with '${user} <option ${option_list}>' to select the mobile number, or reply with '${user} <mfa code>' to use an Apple iDevice MFA code"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${auth_log_text}")"
}

request_mfa_code()
{
   local request_mfa_text
   request_mfa_text="Please reply with ${user} <6-digit code> in the next 10mins"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${request_mfa_text}")"
}

mfa_success()
{
   local mfa_success_text
   mfa_success_text="MFA successfully re-confirmed for ${user}"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${mfa_success_text}")"
}

mfa_failure()
{
   local mfa_failure_text
   mfa_failure_text="MFA failed for ${user}. Please try again"
   send_message "$(echo -e "${notification_icon} *${notification_title}*%0A${mfa_failure_text}")"
}

show_variables()
{
   echo "user: ${user}"
   echo "apple_id: ${apple_id}"
   echo "telegram_chat_id: ${telegram_chat_id}"
   echo "telegram_http: ${telegram_http}"
   echo "telegram_server: ${telegram_server}"
   echo "telegram_token: ${telegram_token}"
   echo "telegram_protocol: ${telegram_protocol}"
   echo "telegram_base_url: ${telegram_base_url}"
   echo "notification_url: ${notification_url}"
}

config_file="/config/icloudpd.conf"
user="$(grep "^user=" ${config_file} | awk -F= '{print $2}')"
apple_id="$(grep "^apple_id=" ${config_file} | awk -F= '{print $2}')"
telegram_chat_id="$(grep "^telegram_chat_id=" ${config_file} | awk -F= '{print $2}')"
telegram_http="$(grep "^telegram_http=" ${config_file} | awk -F= '{print $2}')"
telegram_server="$(grep "^telegram_server=" ${config_file} | awk -F= '{print $2}')"
telegram_token="$(grep "^telegram_token=" ${config_file} | awk -F= '{print $2}')"
notification_title="$(grep "^notification_title=" ${config_file} | awk -F= '{print $2}')"
notification_icon="\xE2\x96\xB6"

if [ "${telegram_http}" = true ]
then
   telegram_protocol="http"
else
   telegram_protocol="https"
fi

if [ "${telegram_server}" ]
then
   telegram_base_url="${telegram_protocol}://${telegram_server}/bot${telegram_token}"
else
   telegram_base_url="${telegram_protocol}://api.telegram.org/bot${telegram_token}"
fi
notification_url="${telegram_base_url}/sendMessage"

if [ "${notification_title}" ]
then
   notification_title="${notification_title//[^a-zA-Z0-9_ ]/}"
else
   notification_title="boredazfcuk/iCloudPD"
fi

# show_variables
if [ "$1" = "smschoice" ]
then
   choose_sms_number
elif [ "$1" = "mfacode" ]
then
   request_mfa_code
elif [ "$1" = "success" ]
then
   mfa_success
elif [ "$1" = "failure" ]
then
   mfa_failure
fi