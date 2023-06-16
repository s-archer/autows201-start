#!/bin/bash -x

# Send output to log file and serial console
mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads
LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

# Run Immediately Before MCPD starts
/usr/bin/setdb provision.extramb 1000 || true
/usr/bin/setdb restjavad.useextramb true || true
/usr/bin/setdb iapplxrpm.timeout 300 || true
/usr/bin/setdb icrd.timeout 180 || true
/usr/bin/setdb restjavad.timeout 180 || true
/usr/bin/setdb restnoded.timeout 180 || true

# Download or Render BIG-IP Runtime Init Config
cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
{
    "controls": {
        "logLevel": "silly",
        "logFilename": "/var/log/cloud/bigIpRuntimeInit.log"
    },
    "runtime_parameters": [],
    "bigip_ready_enabled": [],
    "pre_onboard_enabled": [
        {
            "name": "provision_rest",
            "type": "inline",
            "commands": [
                "/usr/bin/setdb provision.extramb 1000",
                "/usr/bin/setdb restjavad.useextramb true"
            ]
        }
    ],
    "extension_packages": {
        "install_operations": [
            {
                "extensionType": "do",
                "extensionVersion": "1.37.0",
                "extensionHash": "25dd5256f9fa563e9b2ef9df228d5b01df1aef6b143d7e1c7b9daac822fb91ef"
            },
            {
                "extensionType": "as3",
                "extensionVersion": "3.45.0",
                "extensionHash": "35e7a7efae33a9539e3df52ba594222f93231883f146d4c1fc36737dacc084b8"
            }
        ]
    },
    "extension_services": {
        "service_operations": [
            {
                "extensionType": "do",
                "type": "inline",
                "value": { 
                    "schemaVersion": "1.15.0",
                    "class": "Device",
                    "async": true,
                    "label": "my BIG-IP declaration for declarative onboarding",
                    "Common": {
                        "class": "Tenant",
                        "hostname": "${ hostname }",
                        "admin": {
                            "class": "User",
                            "userType": "regular",
                            "password": "${ admin_pass }",
                            "shell": "bash"
                        },
                        "myDns": {
                            "class": "DNS",
                            "nameServers": [
                                "8.8.8.8"
                            ]
                        },
                        "myNtp": {
                            "class": "NTP",
                            "servers": [
                                "0.pool.ntp.org"
                            ],
                            "timezone": "UTC"
                        },
                        "myProvisioning": {
                            "class": "Provision",
                            "ltm": "nominal"
                        },
                        "external": {
                            "class": "VLAN",
                            "tag": 1001,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": 1.1,
                                    "tagged": false
                                }
                            ]
                        },
                        "external-self": {
                            "class": "SelfIp",
                            "address": "${ external_ip }",
                            "vlan": "external",
                            "allowService": "none",
                            "trafficGroup": "traffic-group-local-only"
                        },
                        "internal": {
                            "class": "VLAN",
                            "tag": 1002,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": 1.2,
                                    "tagged": false
                                }
                            ]
                        },
                        "internal-self": {
                            "class": "SelfIp",
                            "address": "${ internal_ip }",
                            "vlan": "internal",
                            "allowService": "default",
                            "trafficGroup": "traffic-group-local-only"
                        },
                        "dbvars": {
                            "class": "DbVariables",
                            "provision.extramb": 1000,
                            "restjavad.useextramb": true
                        }
                    }
                }
            }
        ]
    },
    "post_onboard_enabled": []
}
EOF

curl https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.1/dist/f5-bigip-runtime-init-1.6.1-1.gz.run -o f5-bigip-runtime-init-1.6.1-1.gz.run && bash f5-bigip-runtime-init-1.6.1-1.gz.run -- '--cloud aws'

f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml