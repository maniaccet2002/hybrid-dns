#!/bin/bash -xe
appprivateip=${appprivateip}
dbprivateip=${dbprivateip}
r53_inbound_ip1=${r53_inbound_ip1}
r53_inbound_ip2=${r53_inbound_ip2}
yum update -y
yum install bind bind-utils -y
cat <<EOF > /etc/named.conf
options {
directory	"/var/named";
dump-file	"/var/named/data/cache_dump.db";
statistics-file "/var/named/data/named_stats.txt";
memstatistics-file "/var/named/data/named_mem_stats.txt";
allow-query { any; };
recursion yes;
forward first;
forwarders {
    192.168.10.2;
};
dnssec-enable yes;
dnssec-validation yes;
dnssec-lookaside auto;
/* Path to ISC DLV key */
bindkeys-file "/etc/named.iscdlv.key";
managed-keys-directory "/var/named/dynamic";
};
zone "corp.animals4life.org" IN {
    type master;
    file "corp.animals4life.org.zone";
    allow-update { none; };
};
zone "aws.company.com" { 
  type forward; 
  forward only;
  forwarders { ${r53_inbound_ip1}; ${r53_inbound_ip2}; }; 
};
EOF
cat <<EOF > /var/named/corp.animals4life.org.zone
\$TTL 86400
@   IN  SOA     ns1.mydomain.com. root.mydomain.com. (
        2013042201  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
; Specify our two nameservers
    IN	NS		dnsA.corp.animals4life.org.
    IN	NS		dnsB.corp.animals4life.org.
; Resolve nameserver hostnames to IP, replace with your two droplet IP addresses.
dnsA		IN	A		1.1.1.1
dnsB	  IN	A		8.8.8.8

; Define hostname -> IP pairs which you wish to resolve
@		  IN	A		${appprivateip}
app		IN	A	  ${appprivateip}
@		  IN	A		${dbprivateip}
db		IN	A	  ${dbprivateip}
EOF
service named restart
chkconfig named on