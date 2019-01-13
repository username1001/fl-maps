FROM node:8.15-stretch

# Install needed deps and clean up after
RUN apt-get update && apt-get install -y -q --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoclean

# meteor installer doesn't work with the default tar binary
RUN apt-get update && apt-get install -y bsdtar \
    && cp $(which tar) $(which tar)~ \
    && ln -sf $(which bsdtar) $(which tar) \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoclean

# install Meteor forcing its progress
RUN curl "https://install.meteor.com/?release=1.6.1.1 " \
    | sed 's/VERBOSITY="--silent"/VERBOSITY="--progress-bar"/' \
    | sh

RUN groupadd -r developer && useradd --no-log-init -r -g developer developer
RUN mkdir -p /home/developer/app
RUN chown -R developer:developer /home/developer

WORKDIR /home/developer/app

COPY . /home/developer/app
RUN chown -R developer:developer /home/developer

# switch to developer to do the install to ensure correct file permissions
USER developer
RUN npm install
RUN meteor npm install

# switch back to root to put back the original tar
USER root
RUN mv $(which tar)~ $(which tar)

# switch back to developer to run the server
USER developer
WORKDIR /home/developer/app

ENTRYPOINT [ "sh", "-c", "npm run start" ]

