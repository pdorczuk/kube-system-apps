#!/usr/bin/env bash

# Globals
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color
OK="${GREEN}OK${NC}\r\n"


case "$1" in
    install)
        printf "${PURPLE}Create Join Token SealedSecret..."
        echo ""
        read -p "Enter join token (from Teleport server configuration teleport.yaml): " token  
        #encoded_token=$(echo ${token} | base64 -w0)
        echo -n 4e32893c224d7e6fefa08581bd6a7e3d21169def | kubectl create secret -n operations generic teleport-kube-agent-join-token --dry-run=client --from-file=auth-token=/dev/stdin -o yaml > secret.yaml | > /dev/null 2>&1
        kubeseal --controller-namespace operations --controller-name=sealedsecrets-sealed-secrets --format yaml < secret.yaml > sealedsecret.yaml | > /dev/null 2>&1
        rm secret.yaml > /dev/null 2>&1
        printf "${OK}"
        printf "${PURPLE}Deploy Teleport Agent..."        
        kustomize build --enable-helm . | kubectl create -f- > /dev/null 2>&1
        printf "${OK}"
    ;;

    remove)
        printf "${PURPLE}Remove Teleport Agent..."
        kustomize build --enable-helm . | kubectl delete -f- > /dev/null 2>&1
        printf "${OK}"

    ;;
esac