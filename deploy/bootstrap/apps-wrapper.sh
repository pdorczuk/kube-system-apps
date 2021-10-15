#!/usr/bin/env bash

# Globals
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color
OK="${GREEN}OK${NC}\r\n"

app () {
    if [ $2 == "create" ]; then
        printf "${PURPLE}Deploy $1..."
    else
        printf "${PURPLE}Removing $1 deployment..."
    fi
    cd ../../$1/
    kustomize build . | kubectl $2 -f- > /dev/null 2>&1
    cd ../deploy/pre-gitops/
    printf "${OK}"
}

case "$1" in
    create|c)
        app metallb create
        sleep 10
        app certmanager create
        sleep 10
        app nginx create
        sleep 10
        app argocd create
        sleep 10
    ;;

    destroy|d)
        app metallb delete
        app certmanager delete
        app nginx delete
        app argocd delete
    ;;
esac