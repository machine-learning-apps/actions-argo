FROM google/cloud-sdk

LABEL "com.github.actions.name"="Submit Argo Workflows From GitHub"
LABEL "com.github.actions.description"="Trigger Argo (https://argoproj.github.io/) workflows from GitHub Actions"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/machine-learning-apps/actions-argo"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Hamel Husain <hamel.husain@gmail.com>"

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
