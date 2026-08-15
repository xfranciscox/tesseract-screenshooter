# tesseract-screenshooter
Captura de región de la pantalla, lectura de texto en inglés/castellano mediante OCR y copiado automático al portapapeles usando tesseract y la utilidad de captura de pantalla nativa.
___
Guía completa desde cero para configurar tesseract-screenshooter. Este procedimiento creará un sistema automatizado de captura de región, lectura de texto en inglés/castellano mediante OCR y copiado automático al portapapeles (guía para escritorio Xfce; en otros escritorios se puede instalar usando el instalador automático - LEER AL FINAL).
## 1. Instalar las dependencias necesarias
Abre tu terminal y ejecuta el siguiente comando para instalar el capturador de Xfce, el motor OCR con sus idiomas y la herramienta para gestionar el portapapeles:

```sudo apt update && sudo apt install xfce4-screenshooter tesseract-ocr tesseract-ocr-eng tesseract-ocr-spa xclip```

## 2. Crear el script de automatización
Vamos a crear un archivo de texto para el script en una ruta accesible del sistema.

   1. Abre el editor desde la terminal:
   
   ```nano ~/.local/bin/shot-ocr```
   
   (Si la carpeta .local/bin no existe, el sistema la creará o puedes guardarlo directamente en tu carpeta de usuario como ~/shot-ocr.sh).
   2. Pega el siguiente código exacto dentro del archivo:
   ```
   #!/bin/bash# Crear un archivo temporal seguro para la imagen
   TMP=$(mktemp /tmp/screenshot_ocr.XXXXXX)
   # Lanzar el capturador de Xfce en modo región interactiva
   xfce4-screenshooter -r -s "$TMP.png"
   # Verificar si el usuario seleccionó un área y se creó la imagenif [ -f "$TMP.png" ]; then
       # Ejecutar OCR buscando caracteres en inglés y español simultáneamente
       tesseract "$TMP.png" "$TMP" -l eng+spa 2>/dev/null
   
       # Si se generó el texto extraído, procesarlo
       if [ -f "$TMP.txt" ]; then
           # Copiar el texto limpio al portapapeles del sistema
           cat "$TMP.txt" | xclip -selection clipboard
   
           # Enviar una notificación visual de éxito
           notify-send "OCR Completo" "Texto en Inglés/Español copiado al portapapeles."
       fi
   
       # Limpieza absoluta de archivos temporales
       rm -f "$TMP.png" "$TMP" "$TMP.txt"fi
   ```
   3. Guarda los cambios presionando Ctrl + O, confirma con Enter y sal del editor con Ctrl + X.
   4. Concede permisos de ejecución al script para que el sistema pueda iniciarlo:
   
   ```chmod +x ~/.local/bin/shot-ocr```
   
   
## 3. Configurar el atajo de teclado en Xfce
Para vincular el script a la combinación de teclas exacta, sigue estos pasos en tu entorno de escritorio:

   1. Ve al menú de aplicaciones y abre Configuración (Settings) -> Teclado (Keyboard).
   2. Selecciona la pestaña Atajos de aplicación (Application Shortcuts).
   3. Haz clic en el botón Añadir (Add) en la parte inferior.
   4. En el campo "Comando", escribe la ruta absoluta de tu script:
   
   `/home/TU_USUARIO/.local/bin/shot-ocr`
   
   (Reemplaza TU_USUARIO por tu nombre de usuario real en el sistema. También puedes usar el botón de la carpeta para buscar el archivo manualmente).
   5. Haz clic en Aceptar.
   6. El sistema te pedirá que presiones la combinación de teclas. Presiona simultáneamente: Ctrl + Shift + Impr Pant (Print Screen).

## 4. Prueba de funcionamiento
A partir de este momento, cada vez que presiones Ctrl + Shift + Impr Pant:

   1. El cursor se transformará en una cruz.
   2. Selecciona cualquier zona de tu pantalla que contenga texto en inglés o castellano.
   3. Al soltar el clic, el texto se procesará y se guardará en tu memoria. Puedes pegarlo inmediatamente en cualquier documento o chat usando Ctrl + V.
------------------------------

## Script de instalación automática (Xfce - Gnome - KDE)

   1. Guardar el instalador: Descargar el archivo ***instalador_ocr.sh***
   
   2. Dar permisos de ejecución:
   
   `chmod +x instalador_ocr.sh`
   
   3. Ejecutar la instalación:
   
   `./instalador_ocr.sh`
   
   (Nota: El script solicitará tu contraseña de sudo al inicio únicamente para realizar la descarga de las librerías oficiales de Tesseract e xclip/wl-clipboard en caso de que falten en tu sistema).
