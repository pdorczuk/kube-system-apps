#!/usr/bin/env bash

# Globals
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color
OK="${GREEN}OK${NC}\r\n"


install_tools () {
    krew_cfg install
    helm_cfg install
    kubeseal_cfg install
    kustomize_cfg install
    kubectl_aliases_cfg install
    kubelogin_cfg install
}


remove_tools () {
    kubectl_aliases_cfg remove
    kubeseal_cfg remove
    krew_cfg remove
    helm_cfg remove
    kubelogin_cfg remove
    kustomize_cfg remove
}


install_apps () {
    sealed_secrets_cfg install
    argocd_cfg install
}


remove_apps () {
    sealed_secrets_cfg remove
    argocd_cfg remove
}

helm_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install Helm..."
            wget https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz > /dev/null 2>&1
            tar xzf ./helm-v3.7.0-linux-amd64.tar.gz > /dev/null 2>&1
            sudo mv linux-amd64/helm /usr/local/bin/helm > /dev/null 2>&1
            rm ./helm-v3.7.0-linux-amd64.tar.gz
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove Helm..."
            sudo rm -rf /usr/local/bin/helm > /dev/null 2>&1
            printf "${OK}"

        ;;
    esac    
}


kubeseal_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install Kubeseal..."
            wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.16.0/kubeseal-linux-amd64 -O kubeseal > /dev/null 2>&1
            sudo install -m 755 kubeseal /usr/local/bin/kubeseal > /dev/null 2>&1
            rm kubeseal
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove Kubeseal..."
            sudo rm -rf /usr/local/bin/kubeseal > /dev/null 2>&1
            printf "${OK}"

        ;;
    esac    
}


kubelogin_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install Kubelogin..."
            kubectl krew install oidc-login > /dev/null 2>&1
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove Kustomize..."
            kubectl krew uninstall oidc-login > /dev/null 2>&1
            printf "${OK}"

        ;;
    esac    
}


argocd_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install ArgoCD..."
            cd argocd
            echo -n "4e32893c224d7e6fefa08581bd6a7e3d21169def" | kubectl create secret -n operations generic argocd-secret --dry-run=client --from-file=argocd.github.clientSecret=/dev/stdin -o yaml > secret.yaml | > /dev/null 2>&1
            kubeseal --controller-namespace operations --controller-name=sealedsecrets-sealed-secrets --format yaml < secret.yaml > sealedsecret.yaml | > /dev/null 2>&1
            rm secret.yaml > /dev/null 2>&1
            kustomize build --enable-helm . | kubectl create -f- > /dev/null 2>&1
            cd ..
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove ArgoCD..."
            cd argocd
            kustomize build --enable-helm . | kubectl delete -f- > /dev/null 2>&1
            cd ..
            printf "${OK}"

        ;;
    esac    
}


kustomize_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install Kustomize..."
            wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.4.0/kustomize_v4.4.0_linux_amd64.tar.gz > /dev/null 2>&1
            tar xzf ./kustomize_v4.4.0_linux_amd64.tar.gz > /dev/null 2>&1
            sudo mv kustomize /usr/local/bin/ > /dev/null 2>&1
            rm kustomize_v4.4.0_linux_amd64.tar.gz > /dev/null 2>&1
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove Kustomize..."
            sudo rm -rf /usr/local/bin/kustomize > /dev/null 2>&1
            printf "${OK}"

        ;;
    esac    
}


krew_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install kubectl krew..."
            fish ./infrastructure/krew.sh > /dev/null 2>&1
            
            if ! grep -Fxq ".krew"  ~/.config/fish/config.fish
                then
                    sed -i '$ a\set -gx PATH $PATH $HOME/.krew/bin' ~/.config/fish/config.fish
            fi
            printf "${OK}"

        ;;

        remove)
            printf "${PURPLE}Remove kubectl krew..."
            rm -rf -- ~/.krew > /dev/null 2>&1
            sed '/.krew/d' ~/.config/fish/config.fish > /dev/null 2>&1
            printf "${OK}"

        ;;
    esac
}


kubectl_aliases_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Install kubectl fish aliases..."
            git clone https://github.com/ahmetb/kubectl-aliases.git > /dev/null 2>&1

            cp kubectl-aliases/.kubectl_aliases.fish ~/
            
            if ! grep -Fxq ".kubectl_aliases"  ~/.config/fish/config.fish
                then
                    sed -i "$ a\test -f ~/.kubectl_aliases.fish && source (cat ~/.kubectl_aliases.fish | sed -r 's/(kubectl.*) --watch/watch \1/g' | psub)" ~/.config/fish/config.fish
            fi
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove kubectl fish aliases..."
            rm -rf -- ~/.kubectl_aliases.fish > /dev/null 2>&1
            sed '/.kubectl_aliases/d' ~/.config/fish/config.fish > /dev/null 2>&1
            printf "${OK}"

        ;;
    esac
}


sealed_secrets_cfg () {
    case "$1" in
        install)
            printf "${PURPLE}Deploy Bitnami sealed secrets..."
            cd sealedsecrets
            kubectl create -f master.key > /dev/null 2>&1
            kustomize build --enable-helm . | kubectl create -f- > /dev/null 2>&1
            cd ..
            sleep 30 # Give the pod time to boot up otherwise kubeseal commands will fail
            printf "${OK}"
        ;;

        remove)
            printf "${PURPLE}Remove Bitnami sealed secrets..."
            cd sealedsecrets
            kustomize build --enable-helm . | kubectl delete -f- > /dev/null 2>&1
            cd ..
            printf "${OK}"

        ;;
    esac


}


case "$1" in
    rebuild|b)
        printf "${PURPLE}Destroy the cluster..."
        kubectl drain mothership --delete-emptydir-data --force --ignore-daemonsets > /dev/null 2>&1
        sudo kubeadm reset --force > /dev/null 2>&1
        printf "${OK}"
        
        printf "${PURPLE}Clean up iptables..."
        sudo iptables -F > /dev/null 2>&1
        sudo iptables -t nat -F > /dev/null 2>&1
        sudo iptables -t mangle -F > /dev/null 2>&1
        sudo iptables -X > /dev/null 2>&1
        printf "${OK}"

        printf "${PURPLE}Remove kubectl config file..."
        rm -rf $HOME/.kube/config > /dev/null 2>&1
        printf "${OK}"

        # Initialize the cluster using the config file that includes OIDC configuration
        printf "${PURPLE}Create cluster using Kubeadm..."
        sudo kubeadm init --config=./infrastructure/kubeadm/kubeadm-config.yaml > /dev/null 2>&1
        printf "${OK}"
        
        # Copy the root credentials file into my home directory.
        printf "${PURPLE}Copy kubectl config files..."
        mkdir -p $HOME/.kube > /dev/null 2>&1
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config > /dev/null 2>&1
        sudo chown $(id -u):$(id -g) $HOME/.kube/config > /dev/null 2>&1
        printf "${OK}"

        # Allow pods to run on master
        printf "${PURPLE}Taint the node to allow pod scheduling..."
        kubectl taint nodes --all node-role.kubernetes.io/master- > /dev/null 2>&1
        printf "${OK}"

        # Install Calico
        printf "${PURPLE}Install Calico networking..."
        kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml > /dev/null 2>&1
        kubectl create -f ./infrastructure/kubeadm/calico-config.yaml > /dev/null 2>&1
        printf "${OK}"

        remove_tools
        install_tools
        install_apps
    ;;

    repave|p)
        remove_apps
        install_apps
        sleep 15
        kubectl create -f deploy/gitops-apps.yaml
    ;;
esac
