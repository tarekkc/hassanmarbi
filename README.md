# 💼 Système de Gestion - Clients & Versements

## 📋 Description
Application Java Swing moderne pour la gestion des clients et de leurs versements, développée pour le Cabinet Larbi Hassane. Cette application permet de gérer efficacement les informations clients, suivre les paiements et générer des rapports.

## ✨ Fonctionnalités

### 👥 Gestion des Clients
- ➕ Ajouter de nouveaux clients avec toutes leurs informations
- ✏️ Modifier les données clients existantes
- 🗑️ Supprimer des clients (avec leurs versements associés)
- 🔍 Recherche et filtrage avancés
- 📊 Export Excel des données clients
- 🎨 Interface moderne avec thème clair/sombre

### 💰 Gestion des Versements
- 💳 Enregistrer les paiements des clients
- 📈 Suivi automatique des montants restants
- ✏️ Modifier ou supprimer des versements
- 🖨️ Impression de bons de versement
- 📅 Filtrage par date, montant et client
- 🔄 Mise à jour automatique des soldes

### 📊 Tableau de Bord
- 📈 Statistiques en temps réel
- 💰 Total des versements
- 📅 Revenus mensuels
- ⏰ Montants en attente
- 🔄 Actualisation automatique

## 🚀 Installation et Déploiement

### 📋 Prérequis
- **Java 17 ou supérieur** (JRE minimum)
- **MySQL 8.0 ou supérieur**
- **Système d'exploitation**: Windows, macOS, ou Linux

### 🔧 Installation Complète (Nouveau Système)

#### 1. Installation de Java
**Windows:**
1. Téléchargez Java 17 depuis [Oracle](https://www.oracle.com/java/technologies/downloads/) ou [OpenJDK](https://adoptium.net/)
2. Exécutez l'installateur et suivez les instructions
3. Vérifiez l'installation: `java -version` dans l'invite de commande

**macOS:**
```bash
# Avec Homebrew
brew install openjdk@17

# Ou téléchargez depuis le site officiel
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install openjdk-17-jre
```

#### 2. Installation de MySQL
**Windows:**
1. Téléchargez MySQL Installer depuis [mysql.com](https://dev.mysql.com/downloads/installer/)
2. Choisissez "Developer Default" lors de l'installation
3. Configurez le mot de passe root (utilisez `tarek010203` ou modifiez dans le code)

**macOS:**
```bash
# Avec Homebrew
brew install mysql
brew services start mysql
mysql_secure_installation
```

**Linux:**
```bash
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
```

#### 3. Configuration de la Base de Données
```sql
-- Connectez-vous à MySQL en tant que root
mysql -u root -p

-- Créez la base de données
CREATE DATABASE client_management;

-- Créez un utilisateur (optionnel)
CREATE USER 'clientapp'@'localhost' IDENTIFIED BY 'tarek010203';
GRANT ALL PRIVILEGES ON client_management.* TO 'clientapp'@'localhost';
FLUSH PRIVILEGES;

-- Utilisez la base de données
USE client_management;

-- Créez les tables
CREATE TABLE IF NOT EXISTS clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100),
    activite VARCHAR(200) NOT NULL,
    annee VARCHAR(10),
    agent_responsable VARCHAR(100),
    forme_juridique VARCHAR(100),
    regime_fiscal VARCHAR(100),
    regime_cnas VARCHAR(100),
    mode_paiement VARCHAR(100),
    indicateur VARCHAR(100),
    recette_impots VARCHAR(100),
    observation TEXT,
    source INT,
    honoraires_mois VARCHAR(50),
    montant DECIMAL(15,2),
    remaining_balance DECIMAL(15,2),
    phone VARCHAR(20),
    email VARCHAR(100),
    company VARCHAR(200),
    address TEXT,
    type VARCHAR(50),
    premier_versement VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS versement (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    montant DECIMAL(15,2) NOT NULL,
    type VARCHAR(50) NOT NULL,
    date_paiement DATE NOT NULL,
    annee_concernee VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- Créez les index pour de meilleures performances
CREATE INDEX idx_clients_nom ON clients(nom);
CREATE INDEX idx_clients_activite ON clients(activite);
CREATE INDEX idx_versement_client_id ON versement(client_id);
CREATE INDEX idx_versement_date_paiement ON versement(date_paiement);
```

### 📦 Génération de l'Exécutable

#### Option 1: JAR Exécutable (Recommandé)
```bash
# 1. Compilez le projet
javac -cp "lib/*:." -d build clientmanagement/**/*.java

# 2. Créez le fichier MANIFEST.MF
echo "Main-Class: com.yourcompany.clientmanagement.Main" > MANIFEST.MF
echo "Class-Path: lib/flatlaf-3.2.5.jar lib/mysql-connector-java-8.0.33.jar lib/poi-5.2.4.jar lib/poi-ooxml-5.2.4.jar lib/swingx-all-1.6.4.jar" >> MANIFEST.MF

# 3. Créez le JAR
jar cfm ClientManagement.jar MANIFEST.MF -C build . lib/

# 4. Testez l'exécution
java -jar ClientManagement.jar
```

#### Option 2: Script de Lancement
**Windows (run.bat):**
```batch
@echo off
echo Démarrage du Système de Gestion...
java -cp "lib/*;ClientManagement.jar" com.yourcompany.clientmanagement.Main
pause
```

**Linux/macOS (run.sh):**
```bash
#!/bin/bash
echo "Démarrage du Système de Gestion..."
java -cp "lib/*:ClientManagement.jar" com.yourcompany.clientmanagement.Main
```

### 📁 Structure du Package de Déploiement
```
ClientManagement/
├── ClientManagement.jar          # Application principale
├── lib/                          # Bibliothèques requises
│   ├── flatlaf-3.2.5.jar
│   ├── mysql-connector-java-8.0.33.jar
│   ├── poi-5.2.4.jar
│   ├── poi-ooxml-5.2.4.jar
│   └── swingx-all-1.6.4.jar
├── run.bat                       # Script Windows
├── run.sh                        # Script Linux/macOS
├── config/
│   └── database.properties       # Configuration DB (optionnel)
├── docs/
│   ├── README.md
│   └── USER_GUIDE.md
└── sql/
    └── setup.sql                 # Script de création DB
```

### 🔧 Configuration

#### Modification des Paramètres de Base de Données
Si vous devez changer les paramètres de connexion, modifiez le fichier:
`clientmanagement/dao/DatabaseConnection.java`

```java
private static final String URL = "jdbc:mysql://localhost:3306/client_management?useSSL=false&serverTimezone=UTC";
private static final String USER = "root";  // Changez si nécessaire
private static final String PASSWORD = "votre_mot_de_passe";  // Changez ici
```

### 🚀 Déploiement sur d'Autres Ordinateurs

#### 📦 Package Complet (Recommandé)
1. **Créez un installateur avec Java inclus** (pour éviter l'installation Java):
   - Utilisez `jpackage` (Java 14+):
   ```bash
   jpackage --input . --name "Client Management" --main-jar ClientManagement.jar --main-class com.yourcompany.clientmanagement.Main --type exe --win-dir-chooser --win-menu --win-shortcut
   ```

2. **Package portable**:
   - Incluez un JRE portable dans le dossier `jre/`
   - Modifiez le script de lancement pour utiliser le JRE inclus:
   ```batch
   @echo off
   set JAVA_HOME=%~dp0jre
   "%JAVA_HOME%\bin\java" -jar ClientManagement.jar
   ```

#### 🗄️ Base de Données Portable (Alternative)
Pour éviter l'installation MySQL, vous pouvez utiliser H2 Database:

1. **Remplacez MySQL par H2** dans les dépendances
2. **Modifiez la configuration**:
   ```java
   private static final String URL = "jdbc:h2:./data/clientdb;AUTO_SERVER=TRUE";
   private static final String USER = "sa";
   private static final String PASSWORD = "";
   ```

### 🔐 Comptes par Défaut
- **Utilisateur**: `admin` / **Mot de passe**: `admin123`
- **Utilisateur**: `user` / **Mot de passe**: `password`
- **Utilisateur**: `demo` / **Mot de passe**: `demo123`

### 🛠️ Dépannage

#### Problèmes Courants

**1. "java: command not found"**
- Vérifiez que Java est installé: `java -version`
- Ajoutez Java au PATH système

**2. "Access denied for user"**
- Vérifiez les identifiants MySQL
- Assurez-vous que MySQL est démarré
- Vérifiez les permissions utilisateur

**3. "ClassNotFoundException"**
- Vérifiez que toutes les bibliothèques sont dans le dossier `lib/`
- Vérifiez le CLASSPATH dans le script de lancement

**4. "Connection refused"**
- Vérifiez que MySQL est démarré: `sudo service mysql start`
- Vérifiez le port (3306 par défaut)
- Vérifiez le firewall

#### Logs et Débogage
L'application affiche les logs dans la console. Pour capturer les logs:
```bash
java -jar ClientManagement.jar > app.log 2>&1
```

### 📞 Support
Pour toute question ou problème:
- 📧 Email: support@cabinet-larbi.com
- 📱 Téléphone: 0551-053-121
- 🏢 Adresse: 186, Rue Si Lakhdar Lakhdaria

### 📄 Licence
© 2024 Cabinet Larbi Hassane. Tous droits réservés.

---

## 🔄 Mise à Jour

Pour mettre à jour l'application:
1. Sauvegardez votre base de données
2. Remplacez le fichier `ClientManagement.jar`
3. Exécutez les scripts de migration SQL si nécessaire
4. Redémarrez l'application

## 🎯 Fonctionnalités Avancées

### 📊 Export et Rapports
- Export Excel des clients et versements
- Impression de bons de versement
- Rapports de revenus mensuels

### 🎨 Personnalisation
- Thème clair/sombre
- Colonnes personnalisables
- Filtres avancés

### 🔒 Sécurité
- Authentification utilisateur
- Sauvegarde automatique
- Validation des données