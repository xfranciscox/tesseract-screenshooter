#!/bin/bash

# ==============================================================================
# 1. DETECCIÓN DE DEPENDENCIAS E INSTALACIÓN AUTOMÁTICA
# ==============================================================================
echo "=== Paso 1: Verificando e instalando dependencias del sistema ==="

if command -v apt-get &> /dev/null; then
    PM="apt"
elif command -v pacman &> /dev/null; then
    PM="pacman"
elif command -v dnf &> /dev/null; then
    PM="dnf"
else
    echo "Error: No se detectó un gestor de paquetes compatible (APT, Pacman o DNF)."
    exit 1
fi

case "$PM" in
    "apt")
        sudo apt update
        sudo apt install -y tesseract-ocr tesseract-ocr-eng tesseract-ocr-spa xclip wl-clipboard
        ;;
    "pacman")
        sudo pacman -Sy --needed --noconfirm tesseract tesseract-data-eng tesseract-data-spa xclip wl-clipboard
        ;;
    "dnf")
        sudo dnf check-update
        sudo dnf install -y tesseract tesseract-langpack-eng tesseract-langpack-spa xclip wl-clipboard
        ;;
esac

# ==============================================================================
# 2. DETECCIÓN DEL ENTORNO DE ESCRITORIO Y COMANDO NATIVO
# ==============================================================================
echo "=== Paso 2: Detectando entorno de escritorio y servidor gráfico ==="

DESKTOP_ENV="desconocido"
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    DESKTOP_ENV="xfce"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$XDG_CURRENT_DESKTOP" = "KDE:Plasma" ]; then
    DESKTOP_ENV="kde"
elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    DESKTOP_ENV="gnome"
fi

echo "Entorno detectado: $DESKTOP_ENV"

case "$DESKTOP_ENV" in
    "xfce")
        if [ "$PM" = "apt" ]; then sudo apt install -y xfce4-screenshooter; fi
        if [ "$PM" = "pacman" ]; then sudo pacman -S --needed --noconfirm xfce4-screenshooter; fi
        if [ "$PM" = "dnf" ]; then sudo dnf install -y xfce4-screenshooter; fi
        SCREENSHOT_CMD="xfce4-screenshooter -r -s \"\$TMP.png\""
        ;;
    "kde")
        if [ "$PM" = "apt" ]; then sudo apt install -y spectacle; fi
        if [ "$PM" = "pacman" ]; then sudo pacman -S --needed --noconfirm spectacle; fi
        if [ "$PM" = "dnf" ]; then sudo dnf install -y spectacle; fi
        SCREENSHOT_CMD="spectacle -r -b -o \"\$TMP.png\""
        ;;
    "gnome")
        SCREENSHOT_CMD="gnome-screenshot -r -f \"\$TMP.png\" 2>/dev/null || gnome-shell-extension-tool --help &>/dev/null && dbus-send --session --type=method_call --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Screenshot.SelectArea string:\"\$TMP.png\""
        ;;
    *)
        echo "Escritorio no reconocido. Instalando 'scrot' como respaldo..."
        if [ "$PM" = "apt" ]; then sudo apt install -y scrot; fi
        if [ "$PM" = "pacman" ]; then sudo pacman -S --needed --noconfirm scrot; fi
        if [ "$PM" = "dnf" ]; then sudo dnf install -y scrot; fi
        SCREENSHOT_CMD="scrot -s \"\$TMP.png\""
        ;;
esac

# ==============================================================================
# 3. CREACIÓN DE DIRECTORIOS Y DEL SCRIPT DE CAPTURA
# ==============================================================================
echo "=== Paso 3: Creando script de captura universal ==="

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"

SCRIPT_PATH="$HOME/.local/bin/universal-ocr"

cat << EOF > "$SCRIPT_PATH"
#!/bin/bash
TMP=\$(mktemp /tmp/screenshot_ocr.XXXXXX)

$SCREENSHOT_CMD

if [ -f "\$TMP.png" ]; then
    tesseract "\$TMP.png" "\$TMP" -l eng+spa 2>/dev/null
    
    if [ -f "\$TMP.txt" ] && [ -s "\$TMP.txt" ]; then
        if [ "$XDG_SESSION_TYPE" = "wayland" ] && command -v wl-copy &> /dev/null; then
            cat "\$TMP.txt" | wl-copy
        else
            cat "\$TMP.txt" | xclip -selection clipboard
        fi
        notify-send "OCR Completo" "Texto copiado al portapapeles."
    fi
    rm -f "\$TMP.png" "\$TMP" "\$TMP.txt"
fi
EOF

chmod +x "$SCRIPT_PATH"

# ==============================================================================
# 4. CREACIÓN DEL LANZADOR .DESKTOP CON ICONO NATIVO
# ==============================================================================
echo "=== Paso 4: Creando lanzador con icono del sistema ==="

cat << EOF > "$HOME/.local/share/applications/universal-ocr.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Captura OCR Universal
Comment=Extrae texto de la pantalla (Inglés/Español)
Exec=$SCRIPT_PATH
Icon=applets-screenshooter
Terminal=false
Categories=Utility;Graphics;
StartupNotify=true
EOF

chmod +x "$HOME/.local/share/applications/universal-ocr.desktop"
xdg-desktop-menu forceupdate

# ==============================================================================
# 5. ASIGNACIÓN AUTOMÁTICA DEL ATAJO DE TECLADO (Ctrl+Shift+Impr_Pant)
# ==============================================================================
echo "=== Paso 5: Configurando atajo de teclado automático ==="

SHORTCUT_NAME="Captura OCR Universal"
SHORTCUT_KEY="<Primary><Shift>Print"

case "$DESKTOP_ENV" in
    "xfce")
        xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Shift>Print" -n -t string -s "$SCRIPT_PATH"
        echo "Atajo registrado en XFCE."
        ;;
    "gnome")
        PATH_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
        CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        NEW_PATH="${PATH_BASE}/custom_ocr/"
        
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_PATH name "$SHORTCUT_NAME"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_PATH command "$SCRIPT_PATH"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_PATH binding "$SHORTCUT_KEY"
        
        if [ "$CURRENT_BINDINGS" = "@as []" ] || [ "$CURRENT_BINDINGS" = "[]" ]; then
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$NEW_PATH']"
        elif [[ "$CURRENT_BINDINGS" != *"$NEW_PATH"* ]]; then
            MODIFIED_BINDINGS=$(echo "$CURRENT_BINDINGS" | sed "s|\]|, '$NEW_PATH'\]|")
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$MODIFIED_BINDINGS"
        fi
        echo "Atajo registrado en GNOME."
        ;;
    "kde")
        KWRITE_CMD="kwriteconfig6"
        command -v kwriteconfig6 &>/dev/null || KWRITE_CMD="kwriteconfig5"
        
        $KWRITE_CMD --file kglobalshortcutsrc --group "universal-ocr.desktop" --key "_k_custom_shortcut" "Ctrl+Shift+Print"
        $KWRITE_CMD --file kglobalshortcutsrc --group "universal-ocr.desktop" --key "_launch" "Ctrl+Shift+Print,none,Captura OCR Universal"
        
        qdbus org.kde.kglobalaccel /kglobalaccel org.kde.kglobalaccel.reconfigure &>/dev/null
        echo "Atajo registrado en KDE Plasma."
        ;;
    *)
        echo "Aviso: No se pudo configurar el atajo automático. Configúrelo manualmente hacia: $SCRIPT_PATH"
        ;;
esac

echo "=============================================================================="
echo "¡PROCESO COMPLETADO!"
echo "Lanzador configurado para usar el icono nativo de capturas de pantalla de tu tema."
echo "=============================================================================="
