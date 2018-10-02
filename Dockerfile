# Dockerfile to build the FEniCS-X development libraries
#
# Authors: Jack S. Hale <jack.hale@uni.lu> Lizao Li
# <lzlarryli@gmail.com> Garth N. Wells <gnw20@cam.ac.uk> Jan Blechta
# <blechta@karlin.mff.cuni.cz>
#
# To build development environment images:
#
#    docker build --target dev-env-complex -t quay.io/fenicsproject/dolfinx:complex .
#    docker build --target dev-env-real -t quay.io/fenicsproject/dolfinx:latest .
#
# To push images to quay.io:
#
#    docker login quay.io
#    docker push quay.io/fenicsproject/dolfinx:complex
#    docker push quay.io/fenicsproject/dolfinx:latest
#
# To build an image for running Jupyter:
#
#    docker build --target dolfin-notebook -t dolfinx-nb .
#
# To run a notebook:
#
#    docker run -p 8888:8888 dolfinx-nb
#
# To run and share the current host directory with the container:
#
#    docker run -p 8888:8888 -v "$PWD":/tmp dolfinx-nb
#
# NOTE: This should set global arguments, but doesn't seem to work with
# old docker-build
# ARG PYBIND11_VERSION=2.2.4
# ARG PETSC_VERSION=3.10.1
# ARG SLEPC_VERSION=3.10.0
# ARG PETSC4PY_VERSION=3.10.0
# ARG SLEPC4PY_VERSION=3.10.0

FROM ubuntu:18.04 as base
LABEL maintainer="fenics-project <fenics-support@googlegroups.org>"
LABEL description="Base image for real and complex FEniCS test environments"

WORKDIR /tmp

# Environment variables
ENV OPENBLAS_NUM_THREADS=1 \
    OPENBLAS_VERBOSE=0

# Install dependencies available via apt-get
RUN apt-get -qq update && \
    apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confold" upgrade && \
    apt-get -y install \
    cmake \
    doxygen \
    g++ \
    gfortran \
    git \
    gmsh \
    graphviz \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libboost-math-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-timer-dev \
    libeigen3-dev \
    libhdf5-openmpi-dev \
    liblapack-dev \
    libopenmpi-dev \
    libopenblas-dev \
    ninja-build \
    openmpi-bin \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-setuptools \
    valgrind \
    wget \
    bash-completion && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Python packages (via pip)
RUN pip3 install --no-cache-dir mpi4py numpy scipy numba

# Install pybind11
ARG PYBIND11_VERSION=2.2.4
RUN wget -nc --quiet https://github.com/pybind/pybind11/archive/v${PYBIND11_VERSION}.tar.gz && \
    tar -xf v${PYBIND11_VERSION}.tar.gz && \
    cd pybind11-${PYBIND11_VERSION} && \
    mkdir build && \
    cd build && \
    cmake -DPYBIND11_TEST=False ../ && \
    make install && \
    rm -rf /tmp/*


FROM base as dev-env-real
LABEL maintainer="fenics-project <fenics-support@googlegroups.org>"
LABEL description="FEniCS development environment with PETSc real mode"

WORKDIR /tmp

# Install PETSc with real types. PETSc build system needs Python 2 :(.
ARG PETSC_VERSION=3.10.1
RUN apt-get -qq update && \
    apt-get -y install bison flex python && \
    wget -nc --quiet https://bitbucket.org/petsc/petsc/get/v${PETSC_VERSION}.tar.gz -O petsc-${PETSC_VERSION}.tar.gz && \
    mkdir -p petsc-src && tar -xf petsc-${PETSC_VERSION}.tar.gz -C petsc-src --strip-components 1 && \
    cd petsc-src && \
    ./configure \
    --COPTFLAGS="-O2 -g" \
    --CXXOPTFLAGS="-O2 -g" \
    --FOPTFLAGS="-O2 -g" \
    --with-debugging=yes \
    --with-fortran-bindings=no \
    --download-blacs \
    --download-hypre \
    --download-metis \
    --download-mumps \
    --download-ptscotch \
    --download-scalapack \
    --download-spai \
    --download-suitesparse \
    --download-superlu \
    --with-scalar-type=real \
    --prefix=/usr/local/petsc && \
    make && \
    make install && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV PETSC_DIR=/usr/local/petsc

# NOTE: Issues building SLEPc from source tarball generated by
#       Bitbucket. Website tarballs work fine, however.
# Install SLEPc from source with real types
ARG SLEPC_VERSION=3.10.0
RUN wget -nc --quiet http://slepc.upv.es/download/distrib/slepc-${SLEPC_VERSION}.tar.gz -O slepc-${SLEPC_VERSION}.tar.gz && \
    mkdir -p slepc-src && tar -xf slepc-${SLEPC_VERSION}.tar.gz -C slepc-src --strip-components 1 && \
    cd slepc-src && \
    ./configure --prefix=/usr/local/slepc && \
    make && \
    make install && \
    rm -rf /tmp/*
ENV SLEPC_DIR=/usr/local/slepc

# Install petsc4py and slepc4py
ARG PETSC4PY_VERSION=3.10.0
ARG SLEPC4PY_VERSION=3.10.0
RUN pip3 install --no-cache-dir petsc4py==${PETSC4PY_VERSION} && \
    pip3 install --no-cache-dir slepc4py==${SLEPC4PY_VERSION}


FROM base as dev-env-complex
LABEL description="FEniCS development environment with PETSc complex mode"

WORKDIR /tmp

# Install PETSc with complex scalar types
ARG PETSC_VERSION=3.10.1
RUN apt-get -qq update && \
    apt-get -y install bison flex python && \
    wget -nc --quiet https://bitbucket.org/petsc/petsc/get/v${PETSC_VERSION}.tar.gz -O petsc-${PETSC_VERSION}.tar.gz && \
    mkdir -p petsc-src && tar -xf petsc-${PETSC_VERSION}.tar.gz -C petsc-src --strip-components 1 && \
    cd petsc-src && \
    ./configure \
    --COPTFLAGS="-O2 -g" \
    --CXXOPTFLAGS="-O2 -g" \
    --FOPTFLAGS="-O2 -g" \
    --with-debugging=yes \
    --with-fortran-bindings=no \
    --download-blacs \
    --download-metis \
    --download-mumps \
    --download-ptscotch \
    --download-scalapack \
    --download-suitesparse \
    --download-superlu \
    --with-scalar-type=complex \
    --prefix=/usr/local/petsc && \
    make && \
    make install && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV PETSC_DIR=/usr/local/petsc

# Install SLEPc with real and complex scalar types
ARG SLEPC_VERSION=3.10.0
RUN wget -nc --quiet http://slepc.upv.es/download/distrib/slepc-${SLEPC_VERSION}.tar.gz -O slepc-${SLEPC_VERSION}.tar.gz && \
    mkdir -p slepc-src && tar -xf slepc-${SLEPC_VERSION}.tar.gz -C slepc-src --strip-components 1 && \
    cd slepc-src && \
    ./configure --prefix=/usr/local/slepc && \
    make && \
    make install && \
    rm -rf /tmp/*
ENV SLEPC_DIR=/usr/local/slepc

# Install complex petsc4py and slepc4py
ARG PETSC4PY_VERSION=3.10.0
ARG SLEPC4PY_VERSION=3.10.0
RUN pip3 install --no-cache-dir petsc4py==${PETSC4PY_VERSION} && \
    pip3 install --no-cache-dir slepc4py==${SLEPC4PY_VERSION}


FROM dev-env-real as dolfin-real
LABEL description="DOLFIN-X in real mode"

WORKDIR /tmp

# Install FIAT, UFL, dijitso and ffcX (development versions, master branch)
RUN pip3 install --no-cache-dir git+https://bitbucket.org/fenics-project/fiat.git && \
    pip3 install --no-cache-dir git+https://bitbucket.org/fenics-project/ufl.git && \
    pip3 install --no-cache-dir git+https://bitbucket.org/fenics-project/dijitso.git && \
    pip3 install --no-cache-dir git+https://github.com/fenics/ffcX

# Install dolfinx
RUN git clone https://github.com/fenics/dolfinx.git && \
    cd dolfinx && \
    mkdir build && \
    cd build && \
    cmake -G Ninja ../cpp && \
    ninja install && \
    cd ../python && \
    pip3 install . && \
    rm -rf /tmp/*


FROM dev-env-complex as dolfin-complex
LABEL description="DOLFIN-X in complex mode"

WORKDIR /tmp

# Install FIAT, UFL, dijitso and ffcX (development versions, master branch)
RUN pip3 install --no-cache-dir git+https://bitbucket.org/fenics-project/fiat.git && \
    pip3 install --no-cache-dir git+https://bitbucket.org/fenics-project/ufl.git && \
    pip3 install --no-cache-dir git+https://bitbucket.org/fenics-project/dijitso.git && \
    pip3 install --no-cache-dir git+https://github.com/fenics/ffcX

# Install dolfinx
RUN git clone https://github.com/fenics/dolfinx.git && \
    cd dolfinx && \
    mkdir build && \
    cd build && \
    cmake -G Ninja ../cpp && \
    ninja install && \
    cd ../python && \
    pip3 install . && \
    rm -rf /tmp/*


FROM dolfin-real as dolfin-notebook
LABEL description="DOLFIN-X Jupyter Notebook"
WORKDIR /root
RUN pip3 install jupyter
ENTRYPOINT ["jupyter", "notebook", "--ip", "0.0.0.0", "--no-browser", "--allow-root"]


FROM dolfin-complex as dolfin-complex-notebook
LABEL description="DOLFIN-X (complex mode) Jupyter Notebook"
WORKDIR /root
RUN pip3 install jupyter
ENTRYPOINT ["jupyter", "notebook", "--ip", "0.0.0.0", "--no-browser", "--allow-root"]
