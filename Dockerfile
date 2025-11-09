# syntax=docker/dockerfile:1
FROM rockylinux:9.3

# Install ug4 dependencies
RUN dnf update -y
RUN dnf install -y epel-release
RUN dnf config-manager --enable epel
RUN dnf config-manager --enable crb
RUN dnf update -y
RUN dnf install -y wget python3 git cmake openblas-devel openmpi-devel environment-modules
RUN dnf group install -y "Development Tools"

# Setup git credentials
RUN git config --global credential.https://gitlab.com.username d3f_rocky_docker
RUN echo "exec cat /run/secrets/UG4_ACCESS_TOKEN" > /opt/cred.sh
RUN chmod +x /opt/cred.sh
ENV GIT_ASKPASS=/opt/cred.sh

# Setup ughub
WORKDIR /opt/
RUN git clone https://gitlab.com/ug4-project/ughub.git
ENV PATH="$PATH:/opt/ughub"

# Setup minimal ug4
WORKDIR /opt/ug4
ENV UG4_ROOT=/opt/ug4
RUN ughub init
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    ughub install ugcore ConvectionDiffusion Limex JSONForUG4 JSONToolkit ProMesh Richards SuperLU6

# Install submodules
WORKDIR /opt/ug4/plugins/JSONToolkit
RUN git submodule update --init --recursive
WORKDIR /opt/ug4/plugins/SuperLU6
RUN git submodule update --init --recursive
WORKDIR /opt/ug4/externals/JSONForUG4
RUN git submodule update --init --recursive
WORKDIR /opt/ug4/externals/AutodiffForUG4
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    git submodule update --init --recursive

# Install other packages (TODO install via ughub once available)
WORKDIR /opt/ug4/plugins
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    git clone https://gitlab.com/ug4-project/quadruped/d3f.git
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    git clone https://gitlab.com/ug4-project/quadruped/plugin_Parmetis.git
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    git clone https://gitlab.com/ug4-project/quadruped/plugin_LevelSet
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    git clone https://gitlab.com/ug4-project/quadruped/plugin_Smile.git
WORKDIR /opt/ug4/apps
RUN --mount=type=secret,id=UG4_ACCESS_TOKEN \
    git clone https://gitlab.com/ug4-project/quadruped/app_d3f.git
RUN rm /opt/cred.sh

# Build ug4
WORKDIR ${UG4_ROOT}/build
RUN source /etc/profile.d/modules.sh && module load mpi &&\
    cmake .. -DENABLE_ALL_PLUGINS=ON -DCOMPILE_INFO=OFF -DDEBUG=OFF -DCMAKE_BUILD_TYPE=Release -DPARALLEL=ON -DJSON=ON -DUSE_JSON=ON -DJSONToolkit=ON -DSuperLU6=ON
RUN source /etc/profile.d/modules.sh && module load mpi &&\
    make -j8
RUN make install

# Setup user
RUN useradd -ms /bin/bash uguser
RUN chown -R uguser:uguser /opt
RUN chown root:root /opt
USER uguser
WORKDIR /home/uguser
RUN echo "source /opt/ug4/ugcore/scripts/shell/ugbash" >> .bashrc
RUN echo "module load mpi/openmpi-x86_64" >> .bashrc