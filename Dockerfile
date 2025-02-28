# Start with BioSim base image.
ARG BASE_IMAGE=latest
FROM ghcr.io/jimboid/biosim-jupyterhub-base:$BASE_IMAGE

LABEL maintainer="James Gebbie-Rayet <james.gebbie@stfc.ac.uk>"
LABEL org.opencontainers.image.source=https://github.com/jimboid/biosim-aiida-gpcr-workshop
LABEL org.opencontainers.image.description="A container environment for the PSDI workshop on AiiDA tools for data collection."
LABEL org.opencontainers.image.licenses=MIT

ARG TARGETPLATFORM

USER root
WORKDIR /opt/

# Install RabbitMQ for Mac
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    curl \
    ca-certificates \
    erlang \
    unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    wget -c --no-check-certificate https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.10.14/rabbitmq-server-generic-unix-3.10.14.tar.xz && \
    tar -xf rabbitmq-server-generic-unix-3.10.14.tar.xz && \
    rm rabbitmq-server-generic-unix-3.10.14.tar.xz && \
    ln -sf /opt/rabbitmq_server-3.10.14/sbin/* /usr/local/bin/ && \
    chown -R 1000:100 /opt/rabbitmq_server-3.10.14

WORKDIR /tmp

# Grab a specified version of gromacs
RUN wget ftp://ftp.gromacs.org/gromacs/gromacs-2023.4.tar.gz && \
    tar xvf gromacs-2023.4.tar.gz && \
    rm gromacs-2023.4.tar.gz

# make a build dir
RUN mkdir /tmp/gromacs-2023.4/build
WORKDIR /tmp/gromacs-2023.4/build

# build gromacs
RUN cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs-2023.4 -DGMX_BUILD_OWN_FFTW=ON -DGMX_OPENMP=ON -DGMXAPI=OFF -DCMAKE_BUILD_TYPE=Release
RUN make -j8
RUN make install
RUN rm -r /tmp/gromacs-2023.4 && \
    chown -R 1000:100 /opt/gromacs-2023.4

ENV PATH=/opt/gromacs-2023.4/bin:$PATH

USER $NB_USER
WORKDIR $HOME

# Python Dependencies for the md_workshop
RUN conda install mamba
RUN mamba install -c conda-forge -y aiida-core=2.6.3 postgresql=17.2
RUN conda config --env --add pinned_packages postgresql=17.2
#RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
#      conda install conda-forge/linux-64::gromacs=2024.5=nompi_h5f56185_100 -y; \
#    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
#      conda install conda-forge/linux-aarch64::gromacs=2024.5=nompi_h9afd374_100 -y; \
#    fi
RUN pip install aiida-gromacs vermouth==0.9.6
RUN mamba install anaconda::libboost=1.73.0
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      mamba install salilab::dssp; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      mamba install salilab/osx-64::dssp; \
    fi

RUN git clone https://github.com/jimboid/aiida-gromacs.git && \
    mv aiida-gromacs/examples/PTH2R_coarse-grained_files . && \
    mv aiida-gromacs/notebooks/PTH2R_coarse-grained_tutorial.ipynb . && \
    rm -rf aiida-gromacs

COPY --chown=1000:100 .aiida /home/jovyan/.aiida
COPY --chown=1000:100 aiida-stop /home/jovyan/

RUN echo "./aiida-start" >> ~/.bashrc
COPY --chown=1000:100 default-37a8.jupyterlab-workspace /home/jovyan/.jupyter/lab/workspaces/default-37a8.jupyterlab-workspace
COPY --chown=1000:100 aiida-start /home/jovyan/

# UNCOMMENT THIS LINE FOR REMOTE DEPLOYMENT
COPY jupyter_notebook_config.py /etc/jupyter/

# Always finish with non-root user as a precaution.
USER $NB_USER
