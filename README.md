# TP Final Integrador - Conversión color a tonos de gris
Trabajo práctico "Conversión color a tonos de gris" de la materia "Organización del Computador" - 1° cuatrimestre de 2025. Cátedra Benitez. FIUBA.

## Requisitos
- OpenCV (versión 4.x)
- `nasm`
- `cmake` (versión 3.22 o superior)
- `GCC` / `G++`

## Compilación y Ejecución

El proyecto se puede compilar y ejecutar con el script usando:

```bash
chmod +x build.sh
./build.sh
```
O alternativamente con los siguientes comandos:

```bash
mkdir build
cd build
cmake ..
make
```

Luego, para ejecutarlo con el archivo de ejemplo **Casa.jpg**
```bash
./DisplayImage ../Casa.jpg