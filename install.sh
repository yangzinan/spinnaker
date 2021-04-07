#!/bin/bash

VERSION="SPIN_VERSION"
BOMS_DIR="/root/.hal/"
KUBE_DIR="/root/.kube/"
DECK_HOST="spinnaker.xxx.xxx"
GATE_HOST="spin-gate.xxx.xxx"
REGISTRY="harbor.xxx.xxx/xxx"
MINIO_URL="http://minio.xxx.xxx"
MINIO_KEY_ID="AKIAIOSFODNN7EXAMPLE"
MINIO_ACCESS_ID="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

## 下载镜像
function GetImages(){
    echo -e "\033[43;34m =====GetImg===== \033[0m"
    for i in $(cat tagfile.txt); do
        docker pull gcr.azk8s.cn/spinnaker-marketplace/${i}
        docker tag ${REGISTRY}/${i}
        docker push ${REGISTRY}/${i}
    done
    sed -i "s#${REGISTRY}#gcr.azk8s.cn/spinnaker-marketplace#g" halyard.yaml
    
}

function Clean(){
    echo -e "\033[43;34m =====Clean===== \033[0m"
    rm  -r ${BOMS_DIR}/config ${BOMS_DIR}/default 
}

## 安装
function Install(){
    echo -e "\033[43;34m =====Install===== \033[0m"
    [ -d ${BOMS_DIR} ] || mkdir ${BOMS_DIR} 
    mv .boms ${BOMS_DIR}
    ls -a ${BOMS_DIR}
    chmod 777 -R ${BOMS_DIR}
    chmod 777 -R ${KUBE_DIR}
    
    docker run -d  \
    --name halyard   \
    -v ${BOMS_DIR}:/home/spinnaker/.hal \
    -v ${KUBE_DIR}:/home/spinnaker/.kube \
    -it registry.cn-beijing.aliyuncs.com/spinnaker-cd/halyard:1.32.0

    sleep 5

    sed -i "s#DECK_HOST_VAL#${DECK_HOST}#g" halyard.sh
    sed -i "s#GATE_HOST_VAL#${GATE_HOST}#g" halyard.sh
    sed -i "s#VERSION_VAL#${VERSION}#g" halyard.sh
    sed -i "s#MINIO_KEY_ID#${MINIO_KEY_ID}#g" halyard.sh
    sed -i "s#MINIO_ACCESS_ID#${MINIO_ACCESS_ID}#g" halyard.sh
    sed -i "s#MINIO_URL#${MINIO_URL}#g" halyard.sh

    docker cp halyard.yaml halyard:/opt/halyard/config/halyard.yml
    docker stop halyard  &&  docker start halyard
    sleep 3
    docker ps | grep halyard
    sleep 5
    chmod +x halyard.sh
    docker cp halyard.sh halyard:/home/spinnaker/halyard.sh
    docker exec -it halyard ./home/spinnaker/halyard.sh
    sleep 5
    kubectl get pod -n spinnaker
    sleep 5
    kubectl get pod -n spinnaker
}

## Ingress
function Ingress(){
    echo -e "\033[43;34m =====Ingress===== \033[0m"
    sed -i "s/deck_domain/${DECK_HOST}/g" ingress.yaml
    sed -i "s/gate_domain/${GATE_HOST}/g" ingress.yaml
    cat ingress.yaml
    sleep 5
    kubectl create -f  ingress.yaml -n spinnaker 
}


case $1 in 
  clean)
    Clean
    ;;
  getimg)
    GetImages
    ;;
  install)
    Install
    ;;
  ingress)
    Ingress
    ;;
  allinstall)
    Clean
    GetImages
    Install
    sleep 10
    Ingress
    ;;
    
  *)
    echo -e " [getimg -> install -> ingress = allinstall] "
    ;;
esac