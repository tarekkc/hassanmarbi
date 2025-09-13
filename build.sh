#!/bin/bash

echo "========================================"
echo "   Construction du Système de Gestion"
echo "========================================"

# Créer les dossiers nécessaires
mkdir -p build
mkdir -p dist/lib

echo "Compilation des fichiers Java..."

# Compiler tous les fichiers Java
find clientmanagement -name "*.java" -print0 | xargs -0 javac -cp "lib/*" -d build

if [ $? -ne 0 ]; then
    echo "ERREUR: Échec de la compilation"
    exit 1
fi

echo "Création du fichier MANIFEST..."

# Créer le fichier MANIFEST.MF
cat > MANIFEST.MF << EOF
Main-Class: com.yourcompany.clientmanagement.Main
Class-Path: lib/flatlaf-3.2.5.jar lib/mysql-connector-java-8.0.33.jar lib/poi-5.2.4.jar lib/poi-ooxml-5.2.4.jar lib/poi-scratchpad-5.2.4.jar lib/poi-ooxml-lite-5.2.4.jar lib/xmlbeans-5.1.1.jar lib/commons-compress-1.21.jar lib/commons-collections4-4.4.jar lib/swingx-all-1.6.4.jar
EOF

echo "Création du fichier JAR..."

# Créer le JAR exécutable
jar cfm dist/ClientManagement.jar MANIFEST.MF -C build .

if [ $? -ne 0 ]; then
    echo "ERREUR: Échec de la création du JAR"
    exit 1
fi

echo "Copie des bibliothèques..."

# Copier les bibliothèques
cp lib/*.jar dist/lib/

echo "Création des scripts de lancement..."

# Créer le script de lancement Windows
cat > dist/run.bat << 'EOF'
@echo off
echo Démarrage du Système de Gestion...
java -jar ClientManagement.jar
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Impossible de démarrer l'application
    echo Vérifiez que Java est installé et accessible
    pause
)
EOF

# Créer le script de lancement Linux/macOS
cat > dist/run.sh << 'EOF'
#!/bin/bash
echo "Démarrage du Système de Gestion..."
java -jar ClientManagement.jar
if [ $? -ne 0 ]; then
    echo "ERREUR: Impossible de démarrer l'application"
    echo "Vérifiez que Java est installé et accessible"
    read -p "Appuyez sur Entrée pour continuer..."
fi
EOF

# Rendre le script exécutable
chmod +x dist/run.sh

# Nettoyer les fichiers temporaires
rm MANIFEST.MF

echo "========================================"
echo "   Construction terminée avec succès!"
echo "========================================"
echo
echo "Fichiers générés dans le dossier 'dist':"
echo "- ClientManagement.jar (application principale)"
echo "- lib/ (bibliothèques requises)"
echo "- run.bat (script Windows)"
echo "- run.sh (script Linux/macOS)"
echo
echo "Pour tester l'application:"
echo "cd dist"
echo "./run.sh"
echo