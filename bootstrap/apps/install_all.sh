#! /bin/bash

ALL_APPS=(kyverno sealedsecrets argocd argocd-applicationset)

for a in ${ALL_APPS[@]}; do
    cd $a
    kustomize build --enable-helm . | kubectl create -f-
    cd ..
done