# FEniCSx Docker Images

Docker-образы для работы с **FEniCSx / DOLFINx v0.10**, подготовленные на основе официального образа DOLFINx.

Репозиторий содержит две версии:

* **real** — вычисления с вещественными числами;
* **complex** — вычисления с комплексными числами.

Образы опубликованы в **GitHub Container Registry (GHCR)**.

---

## Базовый образ

Используется официальный образ DOLFINx:

```text
ghcr.io/fenics/dolfinx/dolfinx:v0.10.0-r1
```

В базовое окружение входят:

* Python;
* MPI;
* PETSc;
* UFL;
* Basix;
* DOLFINx;
* поддержка HPC и MPI-расчётов.

Дополнительно в пользовательские образы включены инструменты для научных вычислений и визуализации:

* JupyterLab;
* NumPy;
* SciPy;
* Pandas;
* Matplotlib;
* meshio;
* PyVista;
* VTK;
* ParaView;
* Xvfb;
* Mesa / OpenGL;
* Qt/X11-зависимости.

---

# Доступные образы

## 🔹 Real — вещественная арифметика

```bash
docker pull ghcr.io/egoriy286/fenicsx-real:main
```

## 🔹 Complex — комплексная арифметика

```bash
docker pull ghcr.io/egoriy286/fenicsx-complex:main
```

---

# Быстрый старт

## Интерактивный режим

Для вещественной версии:

```bash
docker run -it --rm \
  -p 8888:8888 \
  ghcr.io/egoriy286/fenicsx-real:main \
  bash
```

Для комплексной версии:

```bash
docker run -it --rm \
  -p 8888:8888 \
  ghcr.io/egoriy286/fenicsx-complex:main \
  bash
```

---

# Запуск JupyterLab

Контейнер можно запустить в фоновом режиме:

```bash
docker run -d \
  --name fenicsx-real \
  -p 8888:8888 \
  ghcr.io/egoriy286/fenicsx-real:main
```

Для complex-версии:

```bash
docker run -d \
  --name fenicsx-complex \
  -p 8888:8888 \
  ghcr.io/egoriy286/fenicsx-complex:main
```

После запуска JupyterLab будет доступен по адресу:

```text
http://localhost:8888
```

Пароль:

```text
student123
```

---

# Управление контейнером

Посмотреть запущенные контейнеры:

```bash
docker ps
```

Посмотреть логи:

```bash
docker logs fenicsx-real
```

Подключиться к уже запущенному контейнеру:

```bash
docker exec -it fenicsx-real bash
```

Остановить контейнер:

```bash
docker stop fenicsx-real
```

Удалить остановленный контейнер:

```bash
docker rm fenicsx-real
```

---

# Постоянное хранение файлов

Для сохранения Jupyter Notebook, результатов расчётов и других файлов рекомендуется использовать volume.

Например:

```bash
docker run -d \
  --name fenicsx-real \
  -p 8888:8888 \
  -v "$(pwd)/workspace:/workspace" \
  ghcr.io/egoriy286/fenicsx-real:main
```

Теперь содержимое каталога:

```text
./workspace
```

на хост-системе будет доступно внутри контейнера как:

```text
/workspace
```

На Windows PowerShell можно использовать:

```powershell
docker run -d `
  --name fenicsx-real `
  -p 8888:8888 `
  -v "${PWD}/workspace:/workspace" `
  ghcr.io/egoriy286/fenicsx-real:main
```

---

# Визуализация

В образах присутствует графический стек для **headless rendering**:

* Xvfb;
* Mesa;
* OpenGL;
* GLX/EGL;
* Qt/X11;
* VTK;
* PyVista;
* ParaView.

Это позволяет выполнять визуализацию без физического монитора и без GPU.

Например:

```python
import pyvista as pv

pv.start_xvfb()

sphere = pv.Sphere()

plotter = pv.Plotter(off_screen=True)
plotter.add_mesh(sphere)
plotter.show(screenshot="sphere.png")
```

Полученный файл:

```text
sphere.png
```

можно открыть непосредственно из JupyterLab.

---

# PyVista в JupyterLab

Для интерактивного вывода можно использовать backend `trame`:

```python
import pyvista as pv

pv.set_jupyter_backend("trame")

sphere = pv.Sphere()

plotter = pv.Plotter()
plotter.add_mesh(sphere)
plotter.show()
```

Это позволяет использовать визуализацию VTK/PyVista непосредственно в Jupyter-среде.

---

# ParaView

ParaView установлен внутри образа вместе с необходимыми библиотеками Qt, X11, OpenGL и Mesa.

Проверить установку:

```bash
paraview --version
```

Также доступны Python bindings:

```python
import paraview
print(paraview)
```

При этом контейнер рассчитан прежде всего на **headless / server-side rendering**.

Для полноценного оконного GUI ParaView потребуется соответствующая X11/VNC-инфраструктура. На Windows обычно удобнее запускать ParaView непосредственно на хост-системе и открывать результаты, созданные DOLFINx.

---

# Сохранение результатов FEM

Результаты расчётов можно сохранять в стандартные форматы:

* `.xdmf`;
* `.h5`;
* `.vtu`;
* `.pvd`.

Например:

```python
from dolfinx.io import XDMFFile

with XDMFFile(comm, "result.xdmf", "w") as xdmf:
    xdmf.write_mesh(mesh)
    xdmf.write_function(u)
```

После этого файл можно открыть в ParaView.

---

# MPI

Образы предназначены для MPI-расчётов.

Пример:

```bash
docker exec -it fenicsx-real \
  mpirun -n 4 python3 solver.py
```

Для небольших тестов:

```bash
python3 solver.py
```

---

# Проверка окружения

Проверить версию DOLFINx:

```bash
python3 -c "import dolfinx; print(dolfinx.__version__)"
```

Проверить PETSc:

```bash
python3 -c "from petsc4py import PETSc; print(PETSc.Sys.getVersion())"
```

Проверить MPI:

```bash
mpirun --version
```

Проверить OpenGL:

```bash
glxinfo | grep -E "OpenGL vendor|OpenGL renderer|OpenGL version"
```

Ожидается software rendering через Mesa/LLVMpipe.

---

# Назначение образов

Образы предназначены для:

* численного решения PDE;
* метода конечных элементов (FEM);
* FEniCSx / DOLFINx;
* MPI-расчётов;
* научных вычислений;
* визуализации через PyVista/VTK;
* подготовки результатов для ParaView;
* JupyterLab;
* CI/CD;
* серверных и headless-сред;
* HPC-экспериментов;
* разработки и обучения.

---

# Пример рабочего процесса

Типичный workflow:

```text
DOLFINx
   │
   ├── FEM mesh
   │
   ├── PDE solver
   │
   ├── MPI / PETSc
   │
   └── Results
          │
          ├── XDMF / HDF5
          ├── VTU / PVD
          │
          └── PyVista / ParaView
```

Для ML-задач образ также можно использовать как вычислительный backend:

```text
DOLFINx / FEM
       │
       ▼
  FEM snapshots
       │
       ▼
   NumPy arrays
       │
       ▼
      FNO
       │
       ▼
   Operator learning
```

---

# Лицензия

Проект распространяется под лицензией **MIT**.

Полный текст лицензии находится в файле:

```text
LICENSE
```

Лицензия применяется к дополнительным Dockerfile, конфигурации и исходным материалам данного репозитория.

Используемые сторонние компоненты, включая **FEniCSx, DOLFINx, PETSc, UFL, Basix, VTK, ParaView, Mesa и Python-библиотеки**, распространяются в соответствии с их собственными лицензиями.

---

# Repository structure

Рекомендуемая структура репозитория:

```text
.
├── Dockerfile.real
├── Dockerfile.complex
├── docker-compose.yml
├── LICENSE
├── README.md
└── workspace/
```

Для публикации образов используется:

```text
GitHub Container Registry (GHCR)
```

Образы:

```text
ghcr.io/egoriy286/fenicsx-real:main
ghcr.io/egoriy286/fenicsx-complex:main
```
