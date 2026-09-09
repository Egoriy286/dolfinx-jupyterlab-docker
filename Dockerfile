# ============================================================
# FEniCSx / DOLFINx 0.10
# JupyterLab
# PyVista / VTK
# Xvfb
# Mesa / OpenGL
# ParaView
#
# Без conda
# Ubuntu 24.04 (база DOLFINx v0.10.0-r1)
# ============================================================

FROM ghcr.io/fenics/dolfinx/dolfinx:v0.10.0-r1

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# ------------------------------------------------------------
# 1. Системные зависимости
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
        # XCB / Qt runtime
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
        \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 2. Пользователь
# ------------------------------------------------------------

RUN useradd \
        --create-home \
        --shell /bin/bash \
        fenics

RUN echo "fenics ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get" \
        > /etc/sudoers.d/fenics && \
    chmod 0440 /etc/sudoers.d/fenics

# ------------------------------------------------------------
# 3. Python-пакеты
#
# ВАЖНО:
#   vtk НЕ устанавливаем через pip.
#   VTK приходит вместе с ParaView.
# ------------------------------------------------------------

RUN python3 -m pip install \
        --no-cache-dir \
        --break-system-packages \
        --upgrade pip setuptools wheel

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
# 4. Рабочая директория
# ------------------------------------------------------------

RUN mkdir -p /workspace && \
    chown -R fenics:fenics /workspace

# ------------------------------------------------------------
# 5. Headless OpenGL
# ------------------------------------------------------------

ENV DISPLAY=:99

ENV LIBGL_ALWAYS_SOFTWARE=1
ENV LIBGL_ALWAYS_INDIRECT=0

ENV QT_X11_NO_MITSHM=1
ENV QT_QPA_PLATFORM=xcb

# ------------------------------------------------------------
# 6. Xvfb launcher
# ------------------------------------------------------------

RUN cat > /usr/local/bin/start-xvfb.sh <<'EOF'
#!/bin/bash

set -e

export DISPLAY="${DISPLAY:-:99}"

if ! pgrep -x Xvfb > /dev/null 2>&1; then

    echo "Starting Xvfb on ${DISPLAY}"

    Xvfb "${DISPLAY}" \
        -screen 0 1920x1080x24 \
        -ac \
        +extension GLX \
        +render \
        -noreset \
        > /tmp/xvfb.log 2>&1 &

fi

# Ждём появления X-сервера
for i in $(seq 1 20); do

    if xdpyinfo -display "${DISPLAY}" > /dev/null 2>&1; then
        break
    fi

    sleep 0.5
done

if ! xdpyinfo -display "${DISPLAY}" > /dev/null 2>&1; then
    echo "ERROR: Xvfb failed to start"
    cat /tmp/xvfb.log || true
    exit 1
fi

echo "Xvfb is running on ${DISPLAY}"

exec "$@"
EOF

RUN chmod +x /usr/local/bin/start-xvfb.sh

# ------------------------------------------------------------
# 7. Диагностический скрипт
# ------------------------------------------------------------

RUN cat > /usr/local/bin/check-gui.sh <<'EOF'
#!/bin/bash

set -e

echo "=========================================="
echo "DOLFINx"
echo "=========================================="

python3 - <<'PY'
import dolfinx
print("dolfinx:", dolfinx.__version__)
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

paraview --version

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
PY

echo
echo "=========================================="
echo "OpenGL"
echo "=========================================="

glxinfo -display "${DISPLAY:-:99}" \
    | grep -E \
    "OpenGL vendor|OpenGL renderer|OpenGL version" \
    || true

echo
echo "=========================================="
echo "DISPLAY"
echo "=========================================="

echo "DISPLAY=${DISPLAY:-:99}"

echo
echo "=========================================="
echo "X server"
echo "=========================================="

xdpyinfo -display "${DISPLAY:-:99}" \
    | head -20
EOF

RUN chmod +x /usr/local/bin/check-gui.sh

# ------------------------------------------------------------
# 8. Jupyter
# ------------------------------------------------------------

USER fenics

WORKDIR /workspace

EXPOSE 8888

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--NotebookApp.token='student123'", "--NotebookApp.password='student123'"]
