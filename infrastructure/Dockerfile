FROM ubuntu:latest

RUN apt update && apt install -y apt-transport-https ca-certificates curl wget git && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt update && apt install -y kubectl && \
    mkdir /root/.kube

RUN wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.16.0/kubeseal-linux-amd64 -O kubeseal && \
    install -m 755 kubeseal /usr/local/bin/kubeseal && \
    rm kubeseal

RUN wget https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz && \
    tar xzf ./helm-v3.7.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm ./helm-v3.7.0-linux-amd64.tar.gz

RUN wget https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz && \
    tar zxvf krew.tar.gz && \
    ./krew-linux_amd64 install krew && \
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc && \
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" && kubectl krew install oidc-login && \
    rm -rf krew*

RUN wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.4.0/kustomize_v4.4.0_linux_amd64.tar.gz && \
    tar xzf ./kustomize_v4.4.0_linux_amd64.tar.gz && \
    mv kustomize /usr/local/bin/ && \
    rm kustomize_v4.4.0_linux_amd64.tar.gz
