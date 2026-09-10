# FEniCSx Docker Images — Short Guide

Docker images for **FEniCSx / DOLFINx v0.10**.  
Based on the official image:

```text
ghcr.io/fenics/dolfinx/dolfinx:v0.10.0-r1
```

Includes: Python, MPI, PETSc, UFL, Basix, DOLFINx, JupyterLab, NumPy, SciPy, Pandas, Matplotlib, meshio, PyVista, VTK, ParaView, Xvfb, Mesa/OpenGL, Qt/X11.

---

## Images

**Real arithmetic:**

```bash
docker pull ghcr.io/egoriy286/fenicsx-real-v10:main
```

**Complex arithmetic:**

```bash
docker pull ghcr.io/egoriy286/fenicsx-complex-v10:main
```

---

## Quick start

Interactive shell:

```bash
docker run -it --rm -p 8888:8888 \
  ghcr.io/egoriy286/fenicsx-real-v10:main bash
```

For complex, replace the image name with:

```text
ghcr.io/egoriy286/fenicsx-complex:main
```

---

## JupyterLab

Start in background:

```bash
docker run -d --name fenicsx-real -p 8888:8888 \
  ghcr.io/egoriy286/fenicsx-real-v10:main
```

Open:

```text
http://localhost:8888
```

Password:

```text
student123
```

---

## Keep files

Use a volume:

```bash
docker run -d --name fenicsx-real -p 8888:8888 \
  -v "$(pwd)/workspace:/workspace" \
  ghcr.io/egoriy286/fenicsx-real-v10:main
```

PowerShell:

```powershell
docker run -d --name fenicsx-real -p 8888:8888 `
  -v "${PWD}/workspace:/workspace" `
  ghcr.io/egoriy286/fenicsx-real-v10:main
```

---

## Container commands

```bash
docker ps
docker logs fenicsx-real
docker exec -it fenicsx-real bash
docker stop fenicsx-real
docker rm fenicsx-real
```

---

## Visualization

Headless PyVista example:

```python
import pyvista as pv

pv.start_xvfb()

sphere = pv.Sphere()

plotter = pv.Plotter(off_screen=True)
plotter.add_mesh(sphere)
plotter.show(screenshot="sphere.png")
```

Interactive in JupyterLab:

```python
import pyvista as pv

pv.set_jupyter_backend("trame")

plotter = pv.Plotter()
plotter.add_mesh(pv.Sphere())
plotter.show()
```

ParaView check:

```bash
paraview --version
```

---

## Save FEM results

```python
from dolfinx.io import XDMFFile

with XDMFFile(comm, "result.xdmf", "w") as xdmf:
    xdmf.write_mesh(mesh)
    xdmf.write_function(u)
```

Formats: `.xdmf`, `.h5`, `.vtu`, `.pvd`.

---

## MPI

```bash
docker exec -it fenicsx-real \
  mpirun -n 4 python3 solver.py
```

Small tests:

```bash
python3 solver.py
```

---

## Check environment

```bash
python3 -c "import dolfinx; print(dolfinx.__version__)"
python3 -c "from petsc4py import PETSc; print(PETSc.Sys.getVersion())"
mpirun --version
glxinfo | grep -E "OpenGL vendor|OpenGL renderer|OpenGL version"
```

---

## License

MIT. See `LICENSE`.

Third-party components keep their own licenses.

---

## Repository structure

```text
.
├── Dockerfile.real
├── Dockerfile.complex
├── docker-compose.yml
├── LICENSE
├── README.md
└── workspace/
```
