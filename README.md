sslciphertest
=============

A script which tests the supported SSL/TLS ciphers of an given server and port

./sslciphertest.sh <OPTIONS>  
-s : Hostname or IP (required)  
-p : Port (required)  
-t : Enables StartTLS usage. Parameter needs to be smtp, pop3, imap or ftp. (optional)  
-d : Delay between tests. See 'man sleep' for notation. (optional)  
-c : OpenSSL cipher list. (optional)  

Examples:
```bash
./sslciphertest.sh -s example.org -p 443

./sslciphertest.sh -s example.org -p 25 -t smtp -d 30s

./sslciphertest.sh -s example.org -p 25 -t smtp -c HIGH
```
