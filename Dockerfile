#
# handbrake Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Pull base image.
FROM xpra-base_xpra-base

# Define software versions.
# NOTE: x264 version 20171224 is the most recent one that doesn't crash.
ARG HANDBRAKE_VERSION=1.3.3
ARG X264_VERSION=20191217
ARG YAD_VERSION=7.3

# Define software download URLs.
ARG HANDBRAKE_URL=https://github.com/HandBrake/HandBrake/releases/download/${HANDBRAKE_VERSION}/HandBrake-${HANDBRAKE_VERSION}-source.tar.bz2
ARG X264_URL=https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}-2245-stable.tar.bz2
ARG YAD_URL=https://github.com/v1cont/yad/archive/v${YAD_VERSION}.tar.gz

# Other build arguments.

# Set to 'max' to keep debug symbols.
ARG HANDBRAKE_DEBUG_MODE=none

# Define working directory.
WORKDIR /tmp

# Compile HandBrake, libva and Intel Media SDK.
RUN \
    add-pkg --virtual build-dependencies \
        # build tools.
        curl \
        build-base \
        yasm \
        autoconf \
        cmake \
        automake \
        libtool \
        m4 \
        patch \
        coreutils \
        tar \
        file \
        python2 \
        linux-headers \
        intltool \
        git \
        diffutils \
        bash \
        nasm \
        meson \
        # misc libraries
        jansson-dev \
        libxml2-dev \
        libpciaccess-dev \
        xz-dev \
        numactl-dev \
        # media libraries
        libsamplerate-dev \
        libass-dev \
        # media codecs
        libtheora-dev \
        lame-dev \
        opus-dev \
        libvorbis-dev \
        speex-dev \
        libvpx-dev \
        # gtk
        gtk+3.0-dev \
        dbus-glib-dev \
        libnotify-dev \
        libgudev-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download x264 sources.
    echo "Downloading x264 sources..." && \
    mkdir x264 && \
    curl -# -L ${X264_URL} | tar xj --strip 1 -C x264 && \
    # Download HandBrake sources.
    echo "Downloading HandBrake sources..." && \
    if echo "${HANDBRAKE_URL}" | grep -q '\.git$'; then \
        git clone ${HANDBRAKE_URL} HandBrake && \
        git -C HandBrake checkout "${HANDBRAKE_VERSION}"; \
    else \
        mkdir HandBrake && \
        curl -# -L ${HANDBRAKE_URL} | tar xj --strip 1 -C HandBrake; \
    fi && \
    # Download helper.
    echo "Downloading helpers..." && \
    curl -# -L -o /tmp/run_cmd https://raw.githubusercontent.com/jlesage/docker-mgmt-tools/master/run_cmd && \
    chmod +x /tmp/run_cmd && \
    # Compile x264.
    echo "Compiling x264..." && \
    cd x264 && \
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then \
        X264_CMAKE_OPTS=--enable-strip; \
    else \
        X264_CMAKE_OPTS=--enable-debug; \
    fi && \
    ./configure \
        --prefix=/usr \
        --enable-shared \
        --enable-pic \
        --disable-cli \
        $X264_CMAKE_OPTS \
        && \
    make -j$(nproc) install && \
    # Compile HandBrake.
    echo "Compiling HandBrake..." && \
    cd /tmp/HandBrake && \
    ./configure --prefix=/usr \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-fdk-aac \
                --enable-x265 \
                --launch-jobs=$(nproc) \
                --launch \
                && \
    /tmp/run_cmd -i 600 -m "HandBrake still compiling..." make --directory=build install && \
    cd .. && \
    # Strip symbols.
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then \
        strip -s /usr/bin/ghb; \
        strip -s /usr/bin/HandBrakeCLI; \
    fi && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -r \
        /usr/lib/pkgconfig/x264.pc \
        /usr/include \
        && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install YAD.
# NOTE: YAD is compiled manually because the version on the Alpine repository
#       pulls too much dependencies.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        autoconf \
        automake \
        intltool \
        curl \
        gtk+3.0-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download.
    mkdir yad && \
    echo "Downloading YAD package..." && \
    curl -# -L ${YAD_URL} | tar xz --strip 1  -C yad && \
    # Compile.
    cd yad && \
    autoreconf -ivf && intltoolize && \
    ./configure \
        --prefix=/usr \
        && \
    make && make install && \
    strip /usr/bin/yad && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN \
    add-pkg \
        gtk+3.0 \
        libgudev \
        dbus-glib \
        libnotify \
        libsamplerate \
        libass \
        jansson \
        xz \
        numactl \
        # Media codecs:
        libtheora \
        lame \
        opus \
        libvorbis \
        speex \
        libvpx \
        # To read encrypted DVDs
        libdvdcss \
        # For main, big icons:
        librsvg \
        # For all other small icons:
        adwaita-icon-theme \
        # For optical drive listing:
        lsscsi \
        # For watchfolder
        bash \
        coreutils \
        findutils \
        expect

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="HandBrake" \
    AUTOMATED_CONVERSION_PRESET="General/Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT="mp4"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]