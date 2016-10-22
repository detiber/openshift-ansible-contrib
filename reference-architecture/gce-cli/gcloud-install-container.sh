#!/bin/bash

# MIT License
#
# Copyright (c) 2016 Peter Schiffer <pschiffe@redhat.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# Script to deploy GCE via OpenShift ansible
#
# Build image using
# docker build -t install-gce -f ../Dockerfile.gce ..

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/config.sh"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat << EOF > working/ansible.env
GCE_ZONE=${GCLOUD_ZONE}
GCE_PEM_FILE_PATH=/usr/local/install/.gce/gce.pem
GCE_EMAIL=${GCLOUD_SERVICE_ACCOUNT}
INVENTORY_IP_TYPE=external
GCE_PROJECT=${GCLOUD_PROJECT}
EOF

# Prepare config file for ansible based on the configuration from this script
export DNS_DOMAIN \
    OCP_APPS_DNS_NAME \
    MASTER_DNS_NAME \
    INTERNAL_MASTER_DNS_NAME \
    CONSOLE_PORT \
    INFRA_NODE_INSTANCE_GROUP_SIZE \
    REGISTRY_BUCKET \
    GCLOUD_PROJECT \
    OCP_NETWORK \
    OCP_IDENTITY_PROVIDERS

envsubst < "${DIR}/ansible-config.yml.tpl" > "${DIR}/working/ansible-config.yml"

docker rm gce || true
docker create --env-file working/ansible.env --name gce install-gce
docker cp ./working/ansible-config.yml gce:/usr/local/install/
docker cp "${GCLOUD_SSH_PRIVATE_KEY}" gce:/home/cloud-user/.ssh/google_compute_engine
docker cp "${GCE_PEM_FILE_PATH}" gce:/usr/local/install/.gce/gce.pem
docker start -a gce
