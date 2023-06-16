{
    "class": "AS3",
    "action": "deploy",
    "persist": true,
    "declaration": {
        "class": "ADC",
        "schemaVersion": "3.45.0",
        "label": "Demo AWS v1.2",
        "remark": "Simple AS3 template for Terraform expansion",
        "day2_tenant": {
            "class": "Tenant"%{ for app in app_list},
            "${app[0]}": {
                "class": "Application",
                "HTTPS_${app[0]}": {
                    "class": "Service_HTTPS",
                    "virtualPort": 443,
                    "redirect80": false,
                    "virtualAddresses": [
                        "${app[5]}"
                    ],
                    "persistenceMethods": [],
                    "profileMultiplex": {
                        "bigip": "/Common/oneconnect"
                    },
                    "pool": "${app[0]}_pool",
                    "serverTLS": "${app[0]}Tls"%{ if waf_enable == true },
                    "policyWAF": {
                        "use": "basePolicy" 
                    }%{ endif }
                },
                "${app[0]}Tls": {
                    "class": "TLS_Server",
                    "certificates": [
                        {
                            "certificate": "${app[0]}_cert"
                        }
                    ]
                },  
                "${app[0]}_cert": {
                  "class": "Certificate",
                  "certificate": "${app[2]}",
                  "privateKey": "${app[3]}"
                },
                "${app[0]}_pool": {
                    "class": "Pool",
                    "monitors": [
                        "http"
                    ],
                    "members": [
                        {
                            "servicePort": 80,
                            "addressDiscovery": "aws",
                            "updateInterval": 1,
                            "tagKey": "Name",
                            "tagValue": "${asg_tag}",
                            "addressRealm": "private",
                            "region": "${app[6]}",
                            "undetectableAction": "disable",
                            "accessKeyId": "${access_key_id}",
                            "secretAccessKey": "${secret_access_key}"
                        }
                    ]
                }%{ if waf_enable == true },
                "basePolicy": {
                    "class": "WAF_Policy",
                    "url": "https://raw.githubusercontent.com/s-archer/waf_policies/master/owasp.json",
                    "ignoreChanges": false,
                    "enforcementMode": "blocking"
                }%{ endif }
            }%{ endfor }
        }
    }
}