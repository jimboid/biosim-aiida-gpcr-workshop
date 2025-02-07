PSDI AiiDA GPCR Workshop
========================

[![aiida gpcr workshop](https://github.com/jimboid/biosim-aiida-gpcr-workshop/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/jimboid/biosim-aiida-gpcr-workshop/actions/workflows/build.yml)

This container is derived from the CCPBioSim JupyterHub image. This container
adds the necessary software packages and notebook content to form a deployable
course container. The source content for this course can be found at
https://github.com/PSDI-UK/aiida-gromacs

How to Use
----------

In our containers we are using the JupyterHub default port 8888, so you should
forward this port when deploying locally::

    docker run -p 8888:8888 harbor.stfc.ac.uk/biosimulation-cloud/biosim-aiida-gpcr-workshop:latest
