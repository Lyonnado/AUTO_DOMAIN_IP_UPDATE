#!/bin/bash

# 提示用户输入 API Token 和域名
echo "请输入你的 API Token:"
read API_TOKEN

echo "请输入用于获取 Zone ID 的域名 (例如 google.com):"
read ZONE_DOMAIN

echo "请输入用于更新 DNS 记录的子域名 (例如 mail.google.com):"
read DNS_DOMAIN

# 获取 Zone ID
echo "正在获取 Zone ID..."
ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=$ZONE_DOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$ZONE_ID" == "null" ]; then
    echo "无法获取 Zone ID，请检查域名 $ZONE_DOMAIN 是否正确。"
    exit 1
fi
echo "Zone ID 获取成功: $ZONE_ID"

# 获取 DNS 记录 ID
echo "正在获取 DNS 记录 ID..."
RECORD_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DNS_DOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$RECORD_ID" == "null" ]; then
    echo "无法获取 DNS 记录 ID，请检查子域名 $DNS_DOMAIN 是否正确。"
    exit 1
fi
echo "DNS 记录 ID 获取成功: $RECORD_ID"

# 获取当前的公网 IP
CURRENT_IP=$(curl -s http://ipecho.net/plain)
echo "当前的公网 IP 地址是: $CURRENT_IP"

# 获取 Cloudflare 上的当前 DNS 记录 IP 地址
CF_IP=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result.content')

# 比较当前 IP 和 Cloudflare 上的 IP 是否一致
if [ "$CURRENT_IP" == "$CF_IP" ]; then
    echo "VPS 的 IP 地址与 DNS 记录中的 IP 地址一致，无需更新。"
else
    # 更新 DNS 记录
    echo "正在更新 DNS 记录..."
    RESPONSE=$(curl -s -
