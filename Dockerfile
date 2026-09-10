# ============================================================
# FEniCSx / DOLFINx 0.10.0-r1 — REAL MODE
# JupyterLab + PyVista + ParaView + Xvfb + Mesa
# ============================================================

FROM ghcr.io/fenics/dolfinx/dolfinx:v0.10.0-r1

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# ------------------------------------------------------------
# 1. System dependencies
# ------------------------------------------------------------

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        git \
        wget \
        curl \
        ca-certificates \
        nano \
        vim \
        \
        # X11 / virtual display
        xvfb \
        xauth \
        x11-utils \
        \
        # OpenGL / Mesa
        mesa-utils \
        libgl1 \
        libegl1 \
        libglx0 \
        libopengl0 \
        libglu1-mesa \
        libgl1-mesa-dri \
        \
        # X11 runtime
        libx11-6 \
        libx11-xcb1 \
        libxext6 \
        libxrender1 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxinerama1 \
        libxcursor1 \
        libxcomposite1 \
        libxdamage1 \
        libxss1 \
        \
        # XCB / Qt
        libxcb1 \
        libxcb-glx0 \
        libxcb-render0 \
        libxcb-shm0 \
        libxcb-xfixes0 \
        libxcb-randr0 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-icccm4 \
        libxcb-util1 \
        libxcb-xinerama0 \
        libxcb-shape0 \
        libxcb-cursor0 \
        \
        # Qt runtime
        libqt5core5t64 \
        libqt5gui5t64 \
        libqt5widgets5t64 \
        libqt5opengl5t64 \
        libqt5network5t64 \
        \
        # Fonts
        libfontconfig1 \
        libfreetype6 \
        \
        # ParaView
        paraview \
        python3-paraview \
    && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 2. Fix /dolfinx-env permissions
# ------------------------------------------------------------

RUN chown -R root:root /dolfinx-env && \
    chmod -R u+rwX /dolfinx-env

# ------------------------------------------------------------
# 3. Create fenics user
# ------------------------------------------------------------

RUN useradd \
        --create-home \
        --shell /bin/bash \
        fenics && \
    echo "fenics ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get" \
        > /etc/sudoers.d/fenics && \
    chmod 0440 /etc/sudoers.d/fenics

# ------------------------------------------------------------
# 4. Python packages
#
# VTK is intentionally NOT installed with pip.
# ParaView provides the VTK Python bindings.
# ------------------------------------------------------------

RUN python3 -m pip install \
        --no-cache-dir \
        --break-system-packages \
        --upgrade \
        pip \
        setuptools \
        wheel

RUN python3 -m pip install \
        --no-cache-dir \
        --break-system-packages \
        jupyterlab \
        notebook \
        ipywidgets \
        matplotlib \
        numpy \
        scipy \
        pandas \
        meshio \
        pyvista \
        trame \
        trame-vtk \
        trame-vuetify

# ------------------------------------------------------------
# 5. Workspace
# ------------------------------------------------------------

RUN mkdir -p /workspace && \
    chown -R fenics:fenics /workspace

# ------------------------------------------------------------
# 6. Prepare X11 runtime directories
#
# IMPORTANT:
# Xvfb requires /tmp/.X11-unix to exist and be writable.
# The X server itself runs as the non-root user "fenics".
# ------------------------------------------------------------

RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp && \
    chmod 1777 /tmp/.X11-unix && \
    rm -f /tmp/.X*-lock

# ------------------------------------------------------------
# 7. Headless OpenGL / Qt
# ------------------------------------------------------------

ENV DISPLAY=:99
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV LIBGL_ALWAYS_INDIRECT=0
ENV QT_X11_NO_MITSHM=1
ENV QT_QPA_PLATFORM=xcb
ENV PYVISTA_OFF_SCREEN=true

# ------------------------------------------------------------
# 8. Xvfb launcher
# ------------------------------------------------------------

RUN cat > /usr/local/bin/start-xvfb.sh <<'EOF'
#!/bin/bash

set -u

DISPLAY="${DISPLAY:-:99}"
SCREEN="1920x1080x24"

export DISPLAY

echo "=========================================="
echo "Starting Xvfb"
echo "DISPLAY=${DISPLAY}"
echo "SCREEN=${SCREEN}"
echo "=========================================="

# ----------------------------------------------------------
# Extract display number
# :99 -> 99
# ----------------------------------------------------------

DISPLAY_NUM="${DISPLAY#:}"
DISPLAY_NUM="${DISPLAY_NUM%%.*}"

# ----------------------------------------------------------
# Remove stale lock from previous container run
# ----------------------------------------------------------

rm -f "/tmp/.X${DISPLAY_NUM}-lock"

# ----------------------------------------------------------
# Make sure X11 socket directory exists.
# This is the critical fix for:
#
# _XSERVTransmkdir:
# euid != 0,
# directory /tmp/.X11-unix will not be created
# ----------------------------------------------------------

if [ ! -d /tmp/.X11-unix ]; then
    echo "Creating /tmp/.X11-unix"
    mkdir -p /tmp/.X11-unix
fi

chmod 1777 /tmp/.X11-unix

# ----------------------------------------------------------
# Remove stale socket for this display
# ----------------------------------------------------------

rm -f "/tmp/.X11-unix/X${DISPLAY_NUM}"

# ----------------------------------------------------------
# Start Xvfb
# ----------------------------------------------------------

Xvfb "${DISPLAY}" \
    -screen 0 "${SCREEN}" \
    -ac \
    +extension GLX \
    +render \
    -noreset \
    > /tmp/xvfb.log 2>&1 &

XVFB_PID=$!

echo "Xvfb PID=${XVFB_PID}"

# ----------------------------------------------------------
# Wait for X server
# ----------------------------------------------------------

for i in $(seq 1 40); do

    if ! kill -0 "${XVFB_PID}" 2>/dev/null; then
        echo
        echo "ERROR: Xvfb process exited unexpectedly"
        echo "------------------------------------------"
        cat /tmp/xvfb.log || true
        exit 1
    fi

    if xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
        echo "Xvfb is ready on ${DISPLAY}"
        break
    fi

    sleep 0.25
done

# ----------------------------------------------------------
# Final check
# ----------------------------------------------------------

if ! xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
    echo
    echo "ERROR: Xvfb failed to start"
    echo "------------------------------------------"
    cat /tmp/xvfb.log || true
    exit 1
fi

echo
echo "=========================================="
echo "Xvfb READY"
echo "DISPLAY=${DISPLAY}"
echo "=========================================="

exec "$@"
EOF

RUN chmod +x /usr/local/bin/start-xvfb.sh

# ------------------------------------------------------------
# 9. GUI diagnostic script
# ------------------------------------------------------------

RUN cat > /usr/local/bin/check-gui.sh <<'EOF'
#!/bin/bash

set -u

DISPLAY="${DISPLAY:-:99}"
export DISPLAY

echo "=========================================="
echo "DOLFINx"
echo "=========================================="

python3 - <<'PY'
import dolfinx
import numpy as np
from dolfinx import default_scalar_type

print("dolfinx     :", dolfinx.__version__)
print("scalar type :", default_scalar_type)
print(
    "is complex  :",
    np.issubdtype(default_scalar_type, np.complexfloating)
)
PY

echo
echo "=========================================="
echo "Python"
echo "=========================================="

python3 --version

echo
echo "=========================================="
echo "ParaView"
echo "=========================================="

paraview --version || true

echo
echo "=========================================="
echo "VTK"
echo "=========================================="

python3 - <<'PY'
import vtk
print("VTK:", vtk.vtkVersion.GetVTKVersion())
PY

echo
echo "=========================================="
echo "PyVista"
echo "=========================================="

python3 - <<'PY'
import pyvista
print("PyVista:", pyvista.__version__)
print("OFF_SCREEN:", pyvista.OFF_SCREEN)
PY

echo
echo "=========================================="
echo "OpenGL"
echo "=========================================="

glxinfo -display "${DISPLAY}" 2>/dev/null \
    | grep -E \
      "OpenGL vendor|OpenGL renderer|OpenGL version" \
    || true

echo
echo "=========================================="
echo "DISPLAY"
echo "=========================================="

echo "DISPLAY=${DISPLAY}"

echo
echo "=========================================="
echo "X server"
echo "=========================================="

xdpyinfo -display "${DISPLAY}" \
    | head -20 \
    || true

echo
echo "=========================================="
echo "X11 socket"
echo "=========================================="

ls -la /tmp/.X11-unix || true
EOF

RUN chmod +x /usr/local/bin/check-gui.sh

# ------------------------------------------------------------
# 10. Jupyter
# ------------------------------------------------------------

USER fenics

WORKDIR /workspace

EXPOSE 8888

CMD ["/usr/local/bin/start-xvfb.sh", \
     "jupyter", "lab", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--allow-root", \
     "--ServerApp.token=student123", \
     "--ServerApp.password=student123"]
