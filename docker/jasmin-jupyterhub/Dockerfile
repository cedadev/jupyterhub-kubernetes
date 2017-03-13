FROM jupyterhub/jupyterhub

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update &&  \
    apt-get -y install gcc libcurl4-openssl-dev libssl-dev &&  \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/*

RUN pip install git+https://github.com/jupyterhub/kubespawner.git
RUN pip install jupyterhub-dummyauthenticator
RUN pip install git+https://github.com/cedadev/jupyterhub-ceda-auth.git
