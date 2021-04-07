#!/bin/bash

VERSION=VERSION_VAL
DECK_HOST=DECK_HOST_VAL
GATE_HOST=GATE_HOST_VAL
until hal --ready; do sleep 10 ; done

# 设置Spinnaker版本，--version 指定版本
hal config version edit --version local:${VERSION} --no-validate

## 设置时区
hal config edit --timezone Asia/Shanghai

## Storage 配置基于minio搭建的S3存储
hal config storage s3 edit \
        --endpoint MINIO_URL \
        --access-key-id MINIO_KEY_ID \
        --secret-access-key MINIO_ACCESS_ID \
        --bucket spinnaker \
        --path-style-access true --no-validate
hal config storage edit --type s3 --no-validate

# Docker Registry  Docker镜像仓库
# Set the dockerRegistry provider as enabled
hal config provider docker-registry enable --no-validate
hal config provider docker-registry account add dockerhub \
    --address index.docker.io \
    --repositories library/alpine,library/ubuntu,library/centos,library/nginx \
    --no-validate


# 添加account to the kubernetes provider.
hal config provider kubernetes enable --no-validate
hal config provider kubernetes account add default \
    --docker-registries dockerhub \
    --context $(kubectl config current-context) \
    --service-account true \
    --omit-namespaces=kube-system,kube-public \
    --provider-version v2 \
    --no-validate

## 编辑Spinnaker部署选项，分部署部署，名称空间。
hal config deploy edit \
    --account-name default \
    --type distributed \
    --location spinnaker \
    --no-validate

## 开启一些主要的功能
hal config features edit --pipeline-templates true  --no-validate
hal config features edit --artifacts true --no-validate
hal config features edit --managed-pipeline-templates-v2-ui true --no-validate



## 设置deck与gate的域名
hal config security ui edit --override-base-url ${DECK_HOST} --no-validate
hal config security api edit --override-base-url ${GATE_HOST} --no-validate

##发布
hal deploy apply --no-validate