# 🚀 Guide de Déploiement - Système de Gestion

## 📋 Vue d'ensemble
Ce guide vous accompagne dans le déploiement du Système de Gestion sur de nouveaux ordinateurs, même sans Java ou MySQL préinstallés.

## 🎯 Options de Déploiement

### Option 1: Installation Complète (Recommandée)
**Avantages**: Performance optimale, contrôle total
**Inconvénients**: Nécessite l'installation de Java et MySQL

### Option 2: Package Portable
**Avantages**: Aucune installation requise
**Inconvénients**: Taille plus importante, performance légèrement réduite

### Option 3: Installation Automatisée
**Avantages**: Installation en un clic
**Inconvénients**: Nécessite des droits administrateur

## 🔧 Option 1: Installation Complète

### Étape 1: Préparation du Package
```bash
# Exécutez le script de construction
./build.sh  # Linux/macOS
# ou
build.bat   # Windows
```

### Étape 2: Installation sur le Poste Cible

#### A. Installation de Java
**Windows:**
1. Téléchargez Java 17 depuis https://adoptium.net/
2. Exécutez l'installateur
3. Vérifiez: `java -version`

**Linux:**
```bash
sudo apt update
sudo apt install openjdk-17-jre
```

#### B. Installation de MySQL
**Windows:**
1. Téléchargez MySQL Installer
2. Installez MySQL Server
3. Configurez le mot de passe root

**Linux:**
```bash
sudo apt install mysql-server
sudo mysql_secure_installation
```

#### C. Configuration de la Base de Données
```bash
mysql -u root -p < setup.sql
```

#### D. Déploiement de l'Application
1. Copiez le dossier `dist/` vers le poste cible
2. Exécutez `run.bat` (Windows) ou `./run.sh` (Linux)

## 📦 Option 2: Package Portable

### Création du Package Portable

#### A. Inclure un JRE Portable
```bash
# Téléchargez un JRE portable
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8%2B7/OpenJDK17U-jre_x64_windows_hotspot_17.0.8_7.zip

# Extrayez dans le dossier dist/
unzip OpenJDK17U-jre_x64_windows_hotspot_17.0.8_7.zip -d dist/
mv dist/jdk-17.0.8+7-jre dist/jre
```

#### B. Modifier le Script de Lancement
**run_portable.bat:**
```batch
@echo off
echo Démarrage du Système de Gestion (Version Portable)...
set JAVA_HOME=%~dp0jre
"%JAVA_HOME%\bin\java" -jar ClientManagement.jar
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Impossible de démarrer l'application
    pause
)
```

#### C. Base de Données Portable avec H2
Modifiez `DatabaseConnection.java`:
```java
private static final String URL = "jdbc:h2:./data/clientdb;AUTO_SERVER=TRUE;DB_CLOSE_DELAY=-1";
private static final String USER = "sa";
private static final String PASSWORD = "";
```

### Structure du Package Portable
```
ClientManagement_Portable/
├── ClientManagement.jar
├── jre/                          # JRE portable
├── lib/                          # Bibliothèques
├── data/                         # Base de données H2
├── run_portable.bat              # Script Windows
├── run_portable.sh               # Script Linux
└── README_PORTABLE.txt
```

## 🤖 Option 3: Installation Automatisée

### Créer un Installateur Windows avec NSIS

#### A. Script NSIS (installer.nsi)
```nsis
!define APPNAME "Système de Gestion"
!define COMPANYNAME "Cabinet Larbi Hassane"
!define DESCRIPTION "Gestion des clients et versements"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0

RequestExecutionLevel admin

InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"

Page directory
Page instfiles

Section "install"
    SetOutPath $INSTDIR
    
    # Copier les fichiers
    File /r "dist\*"
    
    # Créer les raccourcis
    CreateDirectory "$SMPROGRAMS\${COMPANYNAME}"
    CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\run.bat"
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\run.bat"
    
    # Enregistrer dans le registre
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
    
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "uninstall"
    Delete "$INSTDIR\*.*"
    RMDir /r "$INSTDIR"
    Delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
    Delete "$DESKTOP\${APPNAME}.lnk"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd
```

#### B. Compilation de l'Installateur
```bash
makensis installer.nsi
```

### Script d'Installation Linux (install.sh)
```bash
#!/bin/bash

APP_NAME="Système de Gestion"
INSTALL_DIR="/opt/client-management"
DESKTOP_FILE="/usr/share/applications/client-management.desktop"

echo "Installation du $APP_NAME..."

# Vérifier les droits administrateur
if [ "$EUID" -ne 0 ]; then
    echo "Veuillez exécuter en tant que root (sudo)"
    exit 1
fi

# Installer Java si nécessaire
if ! command -v java &> /dev/null; then
    echo "Installation de Java..."
    apt update
    apt install -y openjdk-17-jre
fi

# Installer MySQL si nécessaire
if ! command -v mysql &> /dev/null; then
    echo "Installation de MySQL..."
    apt install -y mysql-server
    systemctl start mysql
    systemctl enable mysql
fi

# Créer le répertoire d'installation
mkdir -p "$INSTALL_DIR"
cp -r dist/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/run.sh"

# Configurer la base de données
echo "Configuration de la base de données..."
mysql -u root < setup.sql

# Créer le fichier .desktop
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=Gestion des clients et versements
Exec=$INSTALL_DIR/run.sh
Icon=$INSTALL_DIR/icon.png
Terminal=false
Type=Application
Categories=Office;
EOF

echo "Installation terminée!"
echo "Lancez l'application depuis le menu Applications ou exécutez:"
echo "$INSTALL_DIR/run.sh"
```

## 🔄 Scripts de Mise à Jour

### Script de Mise à Jour Automatique (update.bat)
```batch
@echo off
echo Mise à jour du Système de Gestion...

REM Sauvegarder la base de données
echo Sauvegarde de la base de données...
mysqldump -u root -p client_management > backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.sql

REM Arrêter l'application si elle est en cours d'exécution
taskkill /f /im java.exe 2>nul

REM Sauvegarder l'ancienne version
if exist ClientManagement.jar.old del ClientManagement.jar.old
if exist ClientManagement.jar ren ClientManagement.jar ClientManagement.jar.old

REM Copier la nouvelle version
copy ClientManagement_new.jar ClientManagement.jar

REM Exécuter les scripts de migration si nécessaire
if exist migration.sql (
    echo Application des migrations...
    mysql -u root -p client_management < migration.sql
)

echo Mise à jour terminée!
echo Vous pouvez maintenant relancer l'application.
pause
```

## 📊 Monitoring et Maintenance

### Script de Vérification de Santé (health_check.sh)
```bash
#!/bin/bash

echo "=== Vérification de Santé du Système ==="

# Vérifier Java
if command -v java &> /dev/null; then
    echo "✅ Java: $(java -version 2>&1 | head -n 1)"
else
    echo "❌ Java: Non installé"
fi

# Vérifier MySQL
if systemctl is-active --quiet mysql; then
    echo "✅ MySQL: Service actif"
else
    echo "❌ MySQL: Service inactif"
fi

# Vérifier la base de données
mysql -u root -p -e "USE client_management; SELECT COUNT(*) as clients FROM clients;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Base de données: Accessible"
else
    echo "❌ Base de données: Problème de connexion"
fi

# Vérifier l'espace disque
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -lt 90 ]; then
    echo "✅ Espace disque: $DISK_USAGE% utilisé"
else
    echo "⚠️ Espace disque: $DISK_USAGE% utilisé (Attention!)"
fi

# Vérifier les logs d'erreur
if [ -f "app.log" ]; then
    ERROR_COUNT=$(grep -c "ERROR" app.log)
    echo "📊 Erreurs dans les logs: $ERROR_COUNT"
fi

echo "=== Fin de la vérification ==="
```

## 🛠️ Dépannage Avancé

### Problèmes de Performance
```sql
-- Optimiser les index
ANALYZE TABLE clients;
ANALYZE TABLE versement;

-- Vérifier les requêtes lentes
SHOW PROCESSLIST;
```

### Nettoyage de la Base de Données
```sql
-- Supprimer les anciens logs (plus de 6 mois)
DELETE FROM versement WHERE created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);

-- Optimiser les tables
OPTIMIZE TABLE clients;
OPTIMIZE TABLE versement;
```

### Sauvegarde Automatique
```bash
#!/bin/bash
# Ajouter à crontab: 0 2 * * * /path/to/backup.sh

BACKUP_DIR="/backup/client-management"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Sauvegarde de la base de données
mysqldump -u root -p client_management > "$BACKUP_DIR/db_backup_$DATE.sql"

# Sauvegarde des fichiers de configuration
tar -czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" config/

# Nettoyer les anciennes sauvegardes (garder 30 jours)
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Sauvegarde terminée: $DATE"
```

## 📞 Support et Contact

Pour toute assistance lors du déploiement:
- 📧 Email: support@cabinet-larbi.com
- 📱 Téléphone: 0551-053-121
- 🏢 Adresse: 186, Rue Si Lakhdar Lakhdaria

## 📝 Checklist de Déploiement

### Avant le Déploiement
- [ ] Tester l'application sur l'environnement de développement
- [ ] Créer une sauvegarde complète
- [ ] Vérifier les prérequis système
- [ ] Préparer les scripts d'installation

### Pendant le Déploiement
- [ ] Installer Java (si nécessaire)
- [ ] Installer MySQL (si nécessaire)
- [ ] Configurer la base de données
- [ ] Déployer l'application
- [ ] Tester la connexion à la base de données
- [ ] Vérifier l'interface utilisateur

### Après le Déploiement
- [ ] Former les utilisateurs
- [ ] Configurer les sauvegardes automatiques
- [ ] Mettre en place le monitoring
- [ ] Documenter la configuration
- [ ] Planifier la maintenance

---

*Ce guide est maintenu par l'équipe de développement du Cabinet Larbi Hassane.*