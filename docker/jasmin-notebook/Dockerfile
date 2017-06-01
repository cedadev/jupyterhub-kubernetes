FROM cedadev/jasmin-sci-vm:latest

USER root

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER

# Create notebook user
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER &&  \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER $CONDA_DIR

RUN yum install -y jq

USER $NB_USER

# Install conda as notebook user
RUN cd /tmp &&  \
    mkdir -p $CONDA_DIR &&  \
    curl -s https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh  \
      > miniconda.sh &&  \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR &&  \
    rm miniconda.sh &&  \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge &&  \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false &&  \
    conda clean -tipsy

# Install Jupyter Notebook and Hub
RUN conda install --quiet --yes notebook jupyterhub jupyterlab &&  \
    conda clean -tipsy

# Install the nbexamples extension
RUN pip install git+https://github.com/danielballan/nbexamples.git &&  \
    jupyter nbextension install --py nbexamples --user &&  \
    jupyter nbextension enable --py nbexamples --user &&  \
    jupyter serverextension enable --py nbexamples --user

# Install JAP Python as a kernel in Jupyter
#   We install it from a virtualenv owned by the user so that they can pip-install stuff
#   We adjust the kernelspec so that the bin directory of the virtualenv takes
#   priority on the PATH, meaning users can install stuff using pip
RUN virtualenv --system-site-packages $HOME/python &&  \
    $HOME/python/bin/pip install 'six>=1.6.0' &&  \
    $HOME/python/bin/pip install ipykernel &&  \
    $HOME/python/bin/python -m ipykernel install --user  \
                                                 --name=python2  \
                                                 --display-name="Python 2.7 (JAP)" &&  \
    cat $HOME/.local/share/jupyter/kernels/python2/kernel.json |  \
      jq ". |= . + { \"env\": { \"PATH\" : \"$HOME/python/bin:$PATH\" } }" > /tmp/python2.kernel.json &&  \
    mv /tmp/python2.kernel.json $HOME/.local/share/jupyter/kernels/python2/kernel.json &&  \
    rm -f /tmp/python2.kernel.json

USER root

RUN yum remove -y jq

# Install JAP R as a a kernel in Jupyter
#   This step creates $HOME/.local, but as root, so we need to transfer to the notebook user
#   We also create a local R lib and associated Rprofile so that the user can install
#   packages using install.packages
RUN yum install -y libcurl-devel &&  \
    mkdir -p $HOME/R-libs &&  \
    echo -e ".libPaths('$HOME/R-libs')\n" > $HOME/.Rprofile &&  \
    R -q -e "install.packages(c('repr', 'IRdisplay', 'crayon', 'pbdZMQ', 'devtools'), repos='http://www.stats.bris.ac.uk/R/')" &&  \
    R -q -e "devtools::install_github('IRkernel/IRkernel')" &&  \
    R -q -e "IRkernel::installspec(displayname = 'R (JAP)', rprofile = '$HOME/.Rprofile')" &&  \
    chown -R $NB_USER:users $HOME

# Install various notebook scripts
RUN curl -s https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start.sh  \
      > /usr/local/bin/start.sh &&  \
    curl -s https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-notebook.sh  \
      > /usr/local/bin/start-notebook.sh &&  \
    curl -s https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-singleuser.sh  \
      > /usr/local/bin/start-singleuser.sh &&  \
    mkdir -p /etc/jupyter &&  \
    curl -s https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/jupyter_notebook_config.py  \
      > /etc/jupyter/jupyterhub_notebook_config.py &&  \
    chown -R $NB_USER:users /etc/jupyter

# Switch back to notebook user to avoid accidental container runs as root
USER $NB_USER

# Configure ipython kernel to use matplotlib inline backend by default
RUN mkdir -p $HOME/.ipython/profile_default/startup &&  \
    curl -s https://raw.githubusercontent.com/jupyter/docker-stacks/master/scipy-notebook/mplimporthook.py \
      > $HOME/.ipython/profile_default/startup/mplimporthook.py

EXPOSE 8888

# Make sure the singleuser script is present
RUN sh /usr/local/bin/start-singleuser.sh --help-all
CMD ["sh", "/usr/local/bin/start-singleuser.sh"]
