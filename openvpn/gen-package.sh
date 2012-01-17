#!/bin/sh

CA_KEY=${CA_KEY:-/etc/openvpn/ca.key}
CA_CRT=${CA_CRT:-/etc/openvpn/ca.crt}
HOST=${HOST:-example.com}

PACKAGE=$1

raise () {
    echo "Error: $1"
    exit 1
}

init () {
    package=$1
    tmp=`mktemp -d`
    
    # Extract
    tar -x -C ${tmp} -f ${package} ||
      raise "Error unpacking"

    # Build package files
    openssl x509 \
      -req \
      -days 365 \
      -in ${tmp}/client.csr \
      -CA ${CA_CRT} \
      -CAkey ${CA_KEY} \
      -CAcreateserial \
      -out ${tmp}/client.crt    
    cp ${CA_CRT} ${tmp}/ca.crt
    cat > ${tmp}/client.conf <<EOF
# OpenVPN Config

client
dev tun
proto udp
remote ${HOST} 1194
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.pem
comp-lzo
verb 3
EOF
    
    # Update package and clean up
    tar -u -C ${tmp} -f ${package} ca.crt client.conf client.crt
    rm -rf "${tmp}"
}

# Test for CA
[ ! -f "${CA_KEY}" ] &&
  raise "CA key does not exist"

[ ! -f "${CA_CRT}" ] &&
  raise "CA certificate does not exist"

# Make sure package is defined
[ -z "${PACKAGE}" ] &&
  raise "Usage: $0 <user tarball>"

[ ! -f "${PACKAGE}" ] &&
  raise "Package does not exist"

init $PACKAGE

