FROM ubuntu:20.04

ENV LANG=C.UTF-8

# Support various rvm, nvm etc stuff which requires executing profile scripts (-l)
SHELL ["/bin/bash", "-lc"]

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get install -y apt-utils apt-transport-https software-properties-common

# Newest git
RUN apt-add-repository ppa:git-core/ppa -y && apt-get update

RUN set -ex -o pipefail && apt-get install -y \
    # Useful utilities \
    curl zip unzip wget socat man-db rsync moreutils vim lsof graphviz \
    #openjdk-8-jre-headless openjdk-11-jdk-headless openjdk-17-jdk-headless maven ant clojure scala \
    # VCS \
    git \
    # Database clients \
    # mongodb-clients mysql-client postgresql-client jq redis-tools \
    # C/C++ \
    build-essential cmake g++ m4 \
    # TeX \
#    texlive \
#    # Python 3 \
#    python3-pip python3-dev pipenv \
#    # Python 2 \
#    python2-dev python-pip-whl \
    # JSON/YAML
    jq \
    && wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod a+x /usr/local/bin/yq

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t https://github.com/oskarkrawczyk/honukai-iterm-zsh \
    -a 'bindkey -v' \
    -a 'bindkey "^R" history-incremental-search-backward' \
    -p git \
    -p history \
    -p history-substring-search \
    -p jsontools \ 
    -p encode64 \
    && \
    chsh -s /usr/bin/zsh

RUN curl -s "https://get.sdkman.io" | bash && source "/root/.sdkman/bin/sdkman-init.sh" && sed -i -e 's/sdkman_auto_answer=false/sdkman_auto_answer=true/g' /root/.sdkman/etc/config && \
    # JDK20: Latest \
    sdk install java 20-tem && sdk default java 20-tem && \
    java -version && javac -version && \
    sdk install kotlin 1.8.20 && \
    kotlin -version && kotlinc -version && \
    sdk install maven 3.9.1 && sdk default maven 3.9.1 && \
    mvn -version && \
    sdk install gradle 8.1 && sdk default gradle 8.1 && \
    gradle -version \
    && \
    # Setup nvm, Nodejs, npm, yarn \
    curl -s "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | bash && . /root/.nvm/nvm.sh && nvm --version && \
    # Node 18.15.0: Latest LTS \
    nvm install 18.15.0 && node --version && npm --version && \
    npm install --global yarn && yarn --version

### Cloud Tools
RUN set -ex -o pipefail && \
    # Docker \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get install -y docker.io && \
    docker --version && \
    # Kubernetes \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    kubectl version --client

## Docker compose (https://docs.docker.com/compose/install/)
## There are no arm64 builds of docker-compose for version 1.x.x, so version 2.x.x is used
RUN DOCKER_COMPOSE_VERSION=v2.14.0 && \
    set -ex -o pipefail && \
    curl -fsSL "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    rm -f /usr/bin/docker-compose && \
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

CMD ["/usr/bin/zsh"]
