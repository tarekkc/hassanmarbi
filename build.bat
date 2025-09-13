@echo off
echo ========================================
echo    Construction du Système de Gestion
echo ========================================

REM Créer les dossiers nécessaires
if not exist "build" mkdir build
if not exist "dist" mkdir dist
if not exist "dist\lib" mkdir dist\lib

echo Compilation des fichiers Java...

REM Compiler tous les fichiers Java
javac -cp "lib/*" -d build clientmanagement/**/*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Échec de la compilation
    pause
    exit /b 1
)

echo Création du fichier MANIFEST...

REM Créer le fichier MANIFEST.MF
echo Main-Class: com.yourcompany.clientmanagement.Main > MANIFEST.MF
echo Class-Path: lib/flatlaf-3.2.5.jar lib/mysql-connector-java-8.0.33.jar lib/poi-5.2.4.jar lib/poi-ooxml-5.2.4.jar lib/poi-scratchpad-5.2.4.jar lib/poi-ooxml-lite-5.2.4.jar lib/xmlbeans-5.1.1.jar lib/commons-compress-1.21.jar lib/commons-collections4-4.4.jar lib/swingx-all-1.6.4.jar >> MANIFEST.MF

echo Création du fichier JAR...

REM Créer le JAR exécutable
jar cfm dist\ClientManagement.jar MANIFEST.MF -C build .

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Échec de la création du JAR
    pause
    exit /b 1
)

echo Copie des bibliothèques...

REM Copier les bibliothèques
copy lib\*.jar dist\lib\

echo Création des scripts de lancement...

REM Créer le script de lancement Windows
echo @echo off > dist\run.bat
echo echo Démarrage du Système de Gestion... >> dist\run.bat
echo java -jar ClientManagement.jar >> dist\run.bat
echo if %%ERRORLEVEL%% NEQ 0 ( >> dist\run.bat
echo     echo ERREUR: Impossible de démarrer l'application >> dist\run.bat
echo     echo Vérifiez que Java est installé et accessible >> dist\run.bat
echo     pause >> dist\run.bat
echo ) >> dist\run.bat

REM Créer le script de lancement Linux/macOS
echo #!/bin/bash > dist\run.sh
echo echo "Démarrage du Système de Gestion..." >> dist\run.sh
echo java -jar ClientManagement.jar >> dist\run.sh
echo if [ $? -ne 0 ]; then >> dist\run.sh
echo     echo "ERREUR: Impossible de démarrer l'application" >> dist\run.sh
echo     echo "Vérifiez que Java est installé et accessible" >> dist\run.sh
echo     read -p "Appuyez sur Entrée pour continuer..." >> dist\run.sh
echo fi >> dist\run.sh

REM Nettoyer les fichiers temporaires
del MANIFEST.MF

echo ========================================
echo    Construction terminée avec succès!
echo ========================================
echo.
echo Fichiers générés dans le dossier 'dist':
echo - ClientManagement.jar (application principale)
echo - lib/ (bibliothèques requises)
echo - run.bat (script Windows)
echo - run.sh (script Linux/macOS)
echo.
echo Pour tester l'application:
echo cd dist
echo run.bat
echo.
pause