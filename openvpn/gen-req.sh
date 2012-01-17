#!/bin/sh

KEY=$1

# Raise error and exit
raise () {
    echo "Error: $1"
    exit 1
}

# Generate CSR
generate_req () {
    key=$1
    csr=$2
    openssl req -new -key "${key}" -out "${csr}" 1>&2
}

# Initialize key and tarball
init () {
    key=$1
    tmp=`mktemp -d`
    
    # Get key
    if [ -n "$key" ]
    then
        # Use existing key
        [ ! -e "$key" ] &&
          raise "Key does not exist"
    
        cp $key ${tmp}/client.pem
    
    elif [ -z "$key" ]
    then
        # Generate key
        openssl genrsa -aes256 -out ${tmp}/client.pem 4096 1>&2
    fi
    
    # Generate CSR
    generate_req ${tmp}/client.pem ${tmp}/client.csr

    # Tarball
    tar zcf - -C "${tmp}" client.pem client.csr
    
    # Delete working path
    rm -rf $tmp
}

init $KEY

