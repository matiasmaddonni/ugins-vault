#!/bin/bash
# Hook: Protege archivos críticos de ediciones accidentales
# Se ejecuta como PreToolUse en Edit/Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

# Si no hay file_path, permitir (no es una operación de archivo)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Archivos y patrones protegidos
PROTECTED_PATTERNS=(
  "Podfile.lock"
  "Package.resolved"
  ".git/"
  "UginsVault.xcodeproj/project.pbxproj"
  "secrets/"
  ".env"
  "GoogleService-Info.plist"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "⛔ Archivo protegido: $FILE_PATH no puede ser editado por Claude." >&2
    echo "Si necesitás modificar este archivo, hacelo manualmente." >&2
    exit 2
  fi
done

exit 0
