#!/bin/bash -xe
appprivateip=${appprivateip}
dbprivateip=${dbprivateip}
r53_inbound_ip1=${r53_inbound_ip1}
r53_inbound_ip2=${r53_inbound_ip2}
aws_dns_name=${aws_dns_name}
onprem_dns_name=${onprem_dns_name}
router_ip=${router_ip}
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
    ${router_ip};
};
dnssec-enable yes;
dnssec-validation yes;
dnssec-lookaside auto;
/* Path to ISC DLV key */
bindkeys-file "/etc/named.iscdlv.key";
managed-keys-directory "/var/named/dynamic";
};
zone "${onprem_dns_name}" IN {
    type master;
    file "${onprem_dns_name}.zone";
    allow-update { none; };
};
zone "${aws_dns_name}" { 
  type forward; 
  forward only;
  forwarders { ${r53_inbound_ip1}; ${r53_inbound_ip2}; }; 
};
EOF
cat <<EOF > /var/named/${onprem_dns_name}.zone
\$TTL 86400
@   IN  SOA     ns1.mydomain.com. root.mydomain.com. (
        2013042201  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
; Specify our two nameservers
    IN	NS		dnsA.${onprem_dns_name}.
    IN	NS		dnsB.${onprem_dns_name}.
; Resolve nameserver hostnames to IP, replace with your two droplet IP addresses.
dnsA		IN	A		1.1.1.1
dnsB	  IN	A		8.8.8.8

; Define hostname -> IP pairs which you wish to resolve
@		  IN	A		${appprivateip}
wordpress		IN	A	  ${appprivateip}
@		  IN	A		${dbprivateip}
wordpressdb		IN	A	  ${dbprivateip}
EOF
service named restart
chkconfig named on