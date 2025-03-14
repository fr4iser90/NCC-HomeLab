#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_DNS_PROVIDERS_LIST_LOADED+x}" ]; then
    return 0
fi
_DNS_PROVIDERS_LIST_LOADED=1

# ==============================================
# DNS Provider Definitions
# ==============================================


# DNS Provider Configuration List
# Format: "Display Name identifier ENV_VAR1 ENV_VAR2 ..."
# 
# Display Name: Human readable name of the provider
# identifier: Technical identifier used in scripts
# ENV_VARx: Required environment variables for this provider
# Declare array as global
declare -ga providers

providers=(
    # A
    "ACME DNS acme-dns ACME_DNS_API_BASE ACME_DNS_STORAGE_PATH"
    "Alibaba Cloud alidns ALICLOUD_ACCESS_KEY ALICLOUD_SECRET_KEY ALICLOUD_REGION_ID"
    "all-inkl allinkl ALL_INKL_LOGIN ALL_INKL_PASSWORD"
    "ArvanCloud arvancloud ARVANCLOUD_API_KEY"
    "Auroradns auroradns AURORA_USER_ID AURORA_KEY AURORA_ENDPOINT"
    "Autodns autodns AUTODNS_API_USER AUTODNS_API_PASSWORD"
    "AzureDNS azuredns AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID AZURE_RESOURCE_GROUP"

    # B
    "Bindman bindman BINDMAN_MANAGER_ADDRESS"
    "Blue Cat bluecat BLUECAT_SERVER_URL BLUECAT_USER_NAME BLUECAT_PASSWORD BLUECAT_CONFIG_NAME BLUECAT_DNS_VIEW"
    "Brandit brandit BRANDIT_API_USERNAME BRANDIT_API_KEY"
    "Bunny bunny BUNNY_API_KEY"

    # C
    "Checkdomain checkdomain CHECKDOMAIN_TOKEN"
    "Civo civo CIVO_TOKEN"
    "Cloud.ru cloudru CLOUDRU_SERVICE_INSTANCE_ID CLOUDRU_KEY_ID CLOUDRU_SECRET"
    "CloudDNS clouddns CLOUDDNS_CLIENT_ID CLOUDDNS_EMAIL CLOUDDNS_PASSWORD"
    "Cloudflare cloudflare CF_API_EMAIL CF_ZONE_ID CF_TOKEN CF_API_KEY"
    "CloudXNS cloudxns CLOUDXNS_API_KEY CLOUDXNS_SECRET_KEY"
    "ConoHa conoha CONOHA_TENANT_ID CONOHA_API_USERNAME CONOHA_API_PASSWORD"
    "Constellix constellix CONSTELLIX_API_KEY CONSTELLIX_SECRET_KEY"
    "CPanel and WHM cpanel CPANEL_MODE CPANEL_USERNAME CPANEL_TOKEN CPANEL_BASE_URL"

    # D
    "Derak Cloud derak DERAK_API_KEY"
    "deSEC desec DESEC_TOKEN"
    "DigitalOcean digitalocean DO_AUTH_TOKEN"
    "DNS Made Easy dnsmadeeasy DNSMADEEASY_API_KEY DNSMADEEASY_API_SECRET DNSMADEEASY_SANDBOX"
    "dnsHome.de dnsHomede DNSHOMEDE_CREDENTIALS"
    "DNSimple dnsimple DNSIMPLE_OAUTH_TOKEN DNSIMPLE_BASE_URL"
    "DNSPod dnspod DNSPOD_API_KEY"
    "Domain Offensive (do.de) dode DODE_TOKEN"
    "Domeneshop domeneshop DOMENESHOP_API_TOKEN DOMENESHOP_API_SECRET"
    "DreamHost dreamhost DREAMHOST_API_KEY"
    "Duck DNS duckdns DUCKDNS_TOKEN"
    "Dyn dyn DYN_CUSTOMER_NAME DYN_USER_NAME DYN_PASSWORD"
    "Dynu dynu DYNU_API_KEY"

    # E
    "EasyDNS easydns EASYDNS_TOKEN EASYDNS_KEY"
    "EdgeDNS edgedns AKAMAI_CLIENT_TOKEN AKAMAI_CLIENT_SECRET AKAMAI_ACCESS_TOKEN"
    "Efficient IP efficientip EFFICIENTIP_USERNAME EFFICIENTIP_PASSWORD EFFICIENTIP_HOSTNAME EFFICIENTIP_DNS_NAME"
    "Epik epik EPIK_SIGNATURE"
    "Exoscale exoscale EXOSCALE_API_KEY EXOSCALE_API_SECRET EXOSCALE_ENDPOINT"

    # F
    "Fast DNS fastdns AKAMAI_CLIENT_TOKEN AKAMAI_CLIENT_SECRET AKAMAI_ACCESS_TOKEN"
    "Freemyip.com freemyip FREEMYIP_TOKEN"

    # G
    "G-Core gcore GCORE_PERMANENT_API_TOKEN"
    "Gandi gandi GANDIV5_PERSONAL_ACCESS_TOKEN"
    "Glesys glesys GLESYS_API_USER GLESYS_API_KEY GLESYS_DOMAIN"
    "GoDaddy godaddy GODADDY_API_KEY GODADDY_API_SECRET"
    "Google Cloud DNS gcloud GCE_PROJECT GCE_SERVICE_ACCOUNT_FILE"
    "Google Domains googledomains GOOGLE_DOMAINS_ACCESS_TOKEN"

    # H
    "Hetzner hetzner HETZNER_API_KEY"
    "hosting.de hostingde HOSTINGDE_API_KEY HOSTINGDE_ZONE_NAME"
    "Hosttech hosttech HOSTTECH_API_KEY"
    "http.net httpnet HTTPNET_API_KEY"
    "Hurricane Electric hurricane HURRICANE_TOKENS"
    "HyperOne hyperone HYPERONE_PASSPORT_LOCATION HYPERONE_LOCATION_ID"

    # I
    "IBM Cloud (SoftLayer) ibmcloud SOFTLAYER_USERNAME SOFTLAYER_API_KEY"
    "IIJ DNS Platform Service iijdpf IIJ_DPF_API_TOKEN IIJ_DPF_DPM_SERVICE_CODE"
    "IIJ iij IIJ_API_ACCESS_KEY IIJ_API_SECRET_KEY IIJ_DO_SERVICE_CODE"
    "Infoblox infoblox INFOBLOX_USERNAME INFOBLOX_PASSWORD INFOBLOX_HOST"
    "Infomaniak infomaniak INFOMANIAK_ACCESS_TOKEN"
    "Internet.bs internetbs INTERNET_BS_API_KEY INTERNET_BS_PASSWORD"
    "INWX inwx INWX_USERNAME INWX_PASSWORD"
    "ionos ionos IONOS_API_KEY"
    "IPv64 ipv64 IPV64_API_KEY"
    "iwantmyname iwantmyname IWANTMYNAME_USERNAME IWANTMYNAME_PASSWORD"

    # J
    "Joker.com joker JOKER_API_MODE JOKER_API_KEY JOKER_USERNAME JOKER_PASSWORD"

    # L
    "Liara liara LIARA_API_KEY"
    "Lightsail lightsail AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY DNS_ZONE"
    "Linode v4 linode LINODE_TOKEN"
    "Liquid Web liquidweb LIQUID_WEB_PASSWORD LIQUID_WEB_USERNAME LIQUID_WEB_ZONE"
    "Loopia loopia LOOPIA_API_PASSWORD LOOPIA_API_USER"
    "LuaDNS luadns LUADNS_API_USERNAME LUADNS_API_TOKEN"

    # M
    "Mail-in-a-Box mailinabox MAILINABOX_EMAIL MAILINABOX_PASSWORD MAILINABOX_BASE_URL"
    "Metaname metaname METANAME_ACCOUNT_REFERENCE METANAME_API_KEY"
    "MyDNS.jp mydnsjp MYDNSJP_MASTER_ID MYDNSJP_PASSWORD"
    "Mythic Beasts mythicbeasts MYTHICBEASTS_USER_NAME MYTHICBEASTS_PASSWORD"

    # N
    "name.com namedotcom NAMECOM_USERNAME NAMECOM_API_TOKEN NAMECOM_SERVER"
    "Namecheap namecheap NAMECHEAP_API_USER NAMECHEAP_API_KEY"
    "Namesilo namesilo NAMESILO_API_KEY"
    "NearlyFreeSpeech.NET nearlyfreespeech NEARLYFREESPEECH_API_KEY NEARLYFREESPEECH_LOGIN"
    "Netcup netcup NETCUP_CUSTOMER_NUMBER NETCUP_API_KEY NETCUP_API_PASSWORD"
    "Netlify netlify NETLIFY_TOKEN"
    "Nicmanager nicmanager NICMANAGER_API_EMAIL NICMANAGER_API_PASSWORD"
    "NIFCloud nifcloud NIFCLOUD_ACCESS_KEY_ID NIFCLOUD_SECRET_ACCESS_KEY"
    "Njalla njalla NJALLA_TOKEN"
    "Nodion nodion NODION_API_TOKEN"
    "NS1 ns1 NS1_API_KEY"

    # O
    "Open Telekom Cloud otc OTC_DOMAIN_NAME OTC_USER_NAME OTC_PASSWORD OTC_PROJECT_NAME OTC_IDENTITY_ENDPOINT"
    "Openstack Designate designate OS_AUTH_URL OS_USERNAME OS_PASSWORD OS_TENANT_NAME OS_REGION_NAME"
    "Oracle Cloud oraclecloud OCI_COMPARTMENT_OCID OCI_PRIVKEY_FILE OCI_PRIVKEY_PASS OCI_PUBKEY_FINGERPRINT OCI_REGION OCI_TENANCY_OCID OCI_USER_OCID"
    "OVH ovh OVH_ENDPOINT OVH_APPLICATION_KEY OVH_APPLICATION_SECRET OVH_CONSUMER_KEY OVH_CLIENT_ID OVH_CLIENT_SECRET"

    # P
    "Plesk plesk PLESK_SERVER_BASE_URL PLESK_USERNAME PLESK_PASSWORD"
    "Porkbun porkbun PORKBUN_SECRET_API_KEY PORKBUN_API_KEY"
    "PowerDNS pdns PDNS_API_KEY PDNS_API_URL"

    # R
    "Rackspace rackspace RACKSPACE_USER RACKSPACE_API_KEY"
    "RcodeZero rcodezero RCODEZERO_API_TOKEN"
    "reg.ru regru REGRU_USERNAME REGRU_PASSWORD"
    "RFC2136 rfc2136 RFC2136_TSIG_KEY RFC2136_TSIG_SECRET RFC2136_TSIG_ALGORITHM RFC2136_NAMESERVER"
    "RimuHosting rimuhosting RIMUHOSTING_API_KEY"
    "Route 53 route53 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_HOSTED_ZONE_ID"

    # S
    "Sakura Cloud sakuracloud SAKURACLOUD_ACCESS_TOKEN SAKURACLOUD_ACCESS_TOKEN_SECRET"
    "Scaleway scaleway SCW_API_TOKEN"
    "Selectel selectel SELECTEL_API_TOKEN"
    "Selectel v2 selectelv2 SELECTELV2_ACCOUNT_ID SELECTELV2_PASSWORD SELECTELV2_PROJECT_ID SELECTELV2_USERNAME"
    "Servercow servercow SERVERCOW_USERNAME SERVERCOW_PASSWORD"
    "Shellrent shellrent SHELLRENT_USERNAME SHELLRENT_TOKEN"
    "Simply.com simply SIMPLY_ACCOUNT_NAME SIMPLY_API_KEY"
    "Sonic sonic SONIC_USER_ID SONIC_API_KEY"
    "Stackpath stackpath STACKPATH_CLIENT_ID STACKPATH_CLIENT_SECRET STACKPATH_STACK_ID"

    # T
    "Tencent Cloud DNS tencentcloud TENCENTCLOUD_SECRET_ID TENCENTCLOUD_SECRET_KEY"
    "TransIP transip TRANSIP_ACCOUNT_NAME TRANSIP_PRIVATE_KEY_PATH"

    # U
    "UKFast SafeDNS safedns SAFEDNS_AUTH_TOKEN"
    "Ultradns ultradns ULTRADNS_USERNAME ULTRADNS_PASSWORD"

    # V
    "Variomedia variomedia VARIOMEDIA_API_TOKEN"
    "VegaDNS vegadns SECRET_VEGADNS_KEY SECRET_VEGADNS_SECRET VEGADNS_URL"
    "Vercel vercel VERCEL_API_TOKEN"
    "Versio versio VERSIO_USERNAME VERSIO_PASSWORD"
    "VinylDNS vinyldns VINYLDNS_ACCESS_KEY VINYLDNS_SECRET_KEY VINYLDNS_HOST"
    "VK Cloud vkcloud VK_CLOUD_PASSWORD VK_CLOUD_PROJECT_ID VK_CLOUD_USERNAME"
    "Vscale vscale VSCALE_API_TOKEN"
    "VULTR vultr VULTR_API_KEY"

    # W
    "Webnames webnames WEBNAMES_API_KEY"
    "Websupport websupport WEBSUPPORT_API_KEY WEBSUPPORT_SECRET"
    "WEDOS wedos WEDOS_USERNAME WEDOS_WAPI_PASSWORD"

    # Y
    "Yandex 360 yandex360 YANDEX360_OAUTH_TOKEN YANDEX360_ORG_ID"
    "Yandex Cloud yandexcloud YANDEX_CLOUD_FOLDER_ID YANDEX_CLOUD_IAM_TOKEN"
    "Yandex yandex YANDEX_PDD_TOKEN"

    # Z
    "Zone.ee zoneee ZONEEE_API_USER ZONEEE_API_KEY"
    "Zonomi zonomi ZONOMI_API_KEY"
)



# Optional: Validation function
validate_provider() {
    local provider_code="$1"
    
    for provider in "${providers[@]}"; do
        if [[ "$provider" =~ $provider_code ]]; then
            return 0
        fi
    done
    
    print_status "Invalid provider code: $provider_code" "error"
    return 1
}