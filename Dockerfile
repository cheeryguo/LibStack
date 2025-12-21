FROM ubuntu:22.04

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    curl \
	zip \
	gzip \
	grep \
	sed \
    make 
	
# Install development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Python
    python3 \
    python3-pip

# Install static check tools including coverage, lint, memory check
RUN apt-get update && apt-get install -y --no-install-recommends \
    # C/C++ static check tools
    clang-tidy \
    cppcheck \
    # C/C++ static check tools
    clang-format \
    clang-extra-tools \
    lcov \
    valgrind \
    vera++ \
    gcovr \
    gtest-dev


# Install cross-compilation toolchains
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ARM64 toolchain
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    # ARM32 toolchain
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    # Windows toolchain
    mingw-w64 \
    gcc-multilib g++-multilib 

# cleanup
RUN apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set git config with user name and email
RUN git config --global user.email "build@example.com" && git config --global user.name "build"

RUN useradd -m -s /bin/bash build && echo "build:build" | chpasswd && adduser build sudo
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir /workspace && \
    chown -R build:build /workspace && \
    chmod g+s /workspace

# set default shell to bash
SHELL ["/bin/bash", "-c"]

#run bash as default command
CMD ["/bin/bash"]

USER build
WORKDIR /workspace
