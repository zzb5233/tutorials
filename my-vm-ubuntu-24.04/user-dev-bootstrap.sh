#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

change_owner_and_group_of_venv_lib_python3_files() {
    local venv
    local user_name
    local group_name

    venv="$1"
    user_name=`id --user --name`
    group_name=`id --group --name`
    sudo chown -R ${user_name}:${group_name} ${venv}/lib/python*/site-packages
}

# Print script commands and exit on errors.
set -xe

#Src
BMV2_COMMIT="005c6cf0f9bb40bfa89d3ca4066ab22f09975d9a"  # 2024-Dec-01
PI_COMMIT="2bb40f7ab800b91b26f3aed174bbbfc739a37ffa"    # 2024-Dec-01
P4C_COMMIT="df9e3ee28ae9b1d9d370c7b8543a953a1c490bc3"   # 2024-Dec-01
PTF_COMMIT="c554f83685186be4cfa9387eb5d6d700d2bbd7c0"   # 2024-Dec-01

# Versions installed by Ubuntu apt
PROTOBUF_PKG_VERSION="3.21.12"
GRPC_PKG_VERSION="1.51.1"
GRPC_VERSION=${GRPC_PKG_VERSION}
# Closest versions available via "pip3 install" to the above
PROTOBUF_VERSION_FOR_PIP="4.21.12"

#Get the number of cores to speed up the compilation process
NUM_CORES=`grep -c ^processor /proc/cpuinfo`

# Change this to a lower value if you do not like all this extra debug
# output.  It is occasionally useful to debug why Python package
# install files, or other files installed system-wide, are not going
# to the places where one might hope.
DEBUG_INSTALL=2

debug_dump_many_install_files() {
    local OUT_FNAME="$1"
    if [ ${DEBUG_INSTALL} -ge 2 ]
    then
	find /usr/lib /usr/local $HOME/.local | sort > "${OUT_FNAME}"
    fi
}

# Create a new Python virtual environment using venv.  Later we will
# attempt to ensure that all new Python packages installed are
# installed into this virtual environment, not into system-wide
# directories like /usr/local/bin
PYTHON_VENV="${HOME}/p4dev-python-venv"
python3 -m venv "${PYTHON_VENV}"
source "${PYTHON_VENV}/bin/activate"

debug_dump_many_install_files $HOME/usr-local-1-before-protobuf.txt

# --- gRPC --- #
sudo apt-get --yes install \
     libprotobuf-dev protobuf-compiler protobuf-compiler-grpc \
     libgrpc-dev libgrpc++-dev
pip3 install protobuf==${PROTOBUF_VERSION_FOR_PIP}

# Check how many hidden symbols are in libprotobuf.a.  When building
# behavioral-model succeeds later, there are only 2 unique hidden
# symbols.  When I see many more unique hidden symbols, building
# behavioral-model later typically fails with an error while trying to
# link with libprotobuf.a
objdump -t /usr/local/lib/libprotobuf.a | grep hidden | sort | uniq -c | wc -l
objdump -t /usr/local/lib/libprotobuf.a | grep hidden | sort | uniq -c | sort -nr | head -n 20

debug_dump_many_install_files $HOME/usr-local-3-after-grpc.txt

# --- PI/P4Runtime --- #
git clone https://github.com/p4lang/PI.git
cd PI
git checkout ${PI_COMMIT}
git submodule update --init --recursive
./autogen.sh
# Cause 'sudo make install' to install Python packages for PI in a
# Python virtual environment, if one is in use.
configure_python_prefix="--with-python_prefix=${PYTHON_VENV}"
./configure --with-proto --without-internal-rpc --without-cli --without-bmv2 ${configure_python_prefix}
# Check what version of protoc is installed before the 'make'
# command below uses protoc on P4Runtime protobuf definition
# files.
which protoc
type -a protoc
protoc --version
set +e
/usr/local/bin/protoc --version
set -e
make -j${NUM_CORES}
sudo make install
make clean
# 'sudo make install' installs several files in ${PYTHON_VENV} with
# root owner.  Change them to be owned by the regular user id.
change_owner_and_group_of_venv_lib_python3_files ${PYTHON_VENV}
sudo ldconfig
cd ..

debug_dump_many_install_files $HOME/usr-local-4-after-PI.txt

# --- Bmv2 --- #
git clone https://github.com/p4lang/behavioral-model.git
sudo mv behavioral-model /dev/shm
sudo ln -s /dev/shm/behavioral-model behavioral-model
cd /dev/shm/behavioral-model
git checkout ${BMV2_COMMIT}
PATCH_DIR="${HOME}/patches"
patch -p1 < "${PATCH_DIR}/behavioral-model-support-venv.patch"
./install_deps.sh
./autogen.sh
./configure --enable-debugger --with-pi --with-thrift ${configure_python_prefix} 'CXXFLAGS=-O0 -g'
make -j${NUM_CORES}
sudo make install-strip
sudo ldconfig
change_owner_and_group_of_venv_lib_python3_files ${PYTHON_VENV}
cd /home/vagrant

debug_dump_many_install_files $HOME/usr-local-5-after-behavioral-model.txt

sudo apt-get autoremove
sudo apt-get clean

# --- P4C --- #
# Starting in 2019-Nov, Python3 version of Scapy is needed for `cd
# p4c/build ; make check` to succeed.
# ply package is needed for ebpf and ubpf backend tests to pass
# TODO: It appears that some changes were made from scapy 2.5.0 to
# 2.6.0 that require changes in P4 open source tools in order to use
# version 2.6.0.  Until those changes are made, install scapy 2.5.0.
pip3 install scapy==2.5.0 ply
git clone https://github.com/p4lang/p4c
sudo mv p4c /dev/shm
sudo ln -s /dev/shm/p4c p4c
cd /dev/shm/p4c
git checkout ${P4C_COMMIT}
git submodule update --init --recursive
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_TEST_TOOLS=ON
# -j3 assumes 6+ GB of RAM and 3+ vCPUs in VM
make -j3
sudo make install/strip
sudo ldconfig
cd ../..
cd /home/vagrant

debug_dump_many_install_files $HOME/usr-local-6-after-p4c.txt

sudo apt-get autoremove
sudo apt-get clean

# --- PTF --- #
git clone https://github.com/p4lang/ptf
cd ptf
git checkout ${PTF_COMMIT}
pip3 install .
cd ..

debug_dump_many_install_files $HOME/usr-local-8-after-ptf-install.txt

# Things needed for `cd tutorials/exercises/basic ; make run` to work:
pip3 install psutil crcmod

# Install p4runtime-shell from source repo, with a slightly modified
# setup.cfg file so that it allows us to keep the version of the
# protobuf package already installed earlier above, without changing
# it, and so that it does _not_ install the p4runtime Python package,
# which would replace the current Python files in
# ${PYTHON_VENV}/lib/python*/site-packages/p4 with ones generated
# using an older version of protobuf.

# First install a known working version of the grpcio package, because
# otherwise installing p4runtime-shell packages will likely pick some
# very recent version of grpcio that may cause trouble.
pip3 install wheel
pip3 install grpcio==1.59.3

git clone https://github.com/p4lang/p4runtime-shell
cd p4runtime-shell
PATCH_DIR="${HOME}/patches"
patch -p1 < "${PATCH_DIR}/p4runtime-shell-2023-changes.patch"
pip3 install .

debug_dump_many_install_files $HOME/usr-local-9-after-p4runtime-shell-install.txt
