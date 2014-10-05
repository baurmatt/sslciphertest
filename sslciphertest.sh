#!/usr/bin/env bash
#
# Copyright (c) 2014 Matthias Baur
# Inspired by indiv (https://superuser.com/questions/109213/is-there-a-tool-that-can-test-what-ssl-tls-cipher-suites-a-particular-website-of/224263#224263)
#
# License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
#
########################################################################

usage(){
  cat <<EOF
$0 <OPTIONS>
-s : Hostname or IP (required)
-p : Port (required)
-t : Enables StartTLS usage. Parameter needs to be smtp, pop3, imap or ftp. (optional)
-d : Delay between tests. See 'man sleep' for notation. (optional)
-c : OpenSSL cipher list. (optional)

Examples:
$0 -s example.org -p 443

$0 -s example.org -p 25 -t smtp -d 30s

$0 -s example.org -p 25 -t smtp -c HIGH
EOF
}

while getopts "s:p:t:d:c:" optname; do
  case "$optname" in
    "s")
      SERVER="$OPTARG"
      ;;
    "p")
      if [[ $OPTARG =~ ^[0-9]+$ ]]; then
        PORT="$OPTARG"
      else
        echo "-p needs to be an numeric value!"
        exit 1
      fi
      ;;
    "t")
      case "$OPTARG" in
        "smtp")
          STARTTLS="-starttls smtp"
          ;;
        "pop3")
          STARTTLS="-starttls pop3"
          ;;
        "imap")
          STARTTLS="-starttls imap"
          ;;
        "ftp")
          STARTTLS="-starttls ftp"
          ;;
        *)
          echo "-t only supports smtp, pop3, imap or ftp. See 'man s_client' for more information."
          exit 1
          ;;
      esac
      ;;
    "d")
      if [[ "$OPTARG" =~ ^[0-9]+[smhd]?$ ]]; then
        DELAY="$OPTARG"
      else
        echo "-d can only be a numeric value followed by s (seconds), m (minutes), h (hours) or d (days). See 'man sleep' from more information."
        exit 1
      fi
      ;;
    "c")
      CIPHERS=$(openssl ciphers "$OPTARG" 2>/dev/null)
      if [ "$?" == "0" ]; then
        CIPHERS=$(echo $CIPHERS | sed -e 's/:/ /g')
      else
        echo "-c needs to a valid OpenSSL cipher. Please validate with 'openssl ciphers "$OPTARG"'."
        echo $CIPHERS
        exit 1
      fi
      ;;
    *)
      echo "Unknown parameter"
      usage
      exit 1
      ;;
  esac
done

if ( [ -z "$SERVER" ] || [ -z "$PORT" ] ); then
  echo -e "-s and -p is required!\n"
  usage
  exit 1
fi

if [ "$CIPHERS" == "" ]; then
  echo Obtaining cipher list from $(openssl version).
  CIPHERS=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')
fi

TEMPOPENSSLPARAM="$STARTTLS -connect $SERVER:$PORT"

echo "Server: $SERVER"
echo "Port  : $PORT"
echo "-----------------------------"

for CIPHER in ${CIPHERS[@]};do
  OPENSSLPARAM="-cipher $CIPHER $TEMPOPENSSLPARAM"
  echo "$OPENSSLPARAM"
  echo -n Testing $CIPHER...
  result=$(echo -n | openssl s_client $OPENSSLPARAM 2>&1)
  if [[ "$result" =~ "Cipher is ${CIPHER}" || "$result" =~ "Cipher    :" ]] ; then
    echo YES
  else
    if [[ "$result" =~ ":error:" ]] ; then
      error=$(echo -n $result | cut -d':' -f6)
      echo NO \($error\)
    else
      echo UNKNOWN RESPONSE
      echo $result
    fi
  fi
  if [ "$DELAY" != "" ]; then
    sleep $DELAY
  fi
done
