FROM google/cloud-sdk:alpine
# this image has all the utilities that I need and is not too bloated

LABEL "com.github.actions.name"="Submit Argo Workflows From GitHub"
LABEL "com.github.actions.description"="Trigger Argo (https://argoproj.github.io/) workflows from GitHub Actions"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="purple"

# Install Argo
RUN curl -sSL -o /usr/local/bin/argo https://github.com/argoproj/argo-workflows/releases/download/v2.2.1/argo-linux-amd64
RUN chmod +x /usr/local/bin/argo

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN gcloud components install kubectl

ENTRYPOINT ["/entrypoint.sh"]
