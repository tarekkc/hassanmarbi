-- ========================================
-- Script de Configuration de Base de Données
-- Système de Gestion - Clients & Versements
-- ========================================

-- Créer la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS client_management 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Utiliser la base de données
USE client_management;

-- ========================================
-- Table des Clients
-- ========================================
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

-- ========================================
-- Table des Versements
-- ========================================
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

-- ========================================
-- Index pour de meilleures performances
-- ========================================
CREATE INDEX IF NOT EXISTS idx_clients_nom ON clients(nom);
CREATE INDEX IF NOT EXISTS idx_clients_activite ON clients(activite);
CREATE INDEX IF NOT EXISTS idx_clients_company ON clients(company);
CREATE INDEX IF NOT EXISTS idx_versement_client_id ON versement(client_id);
CREATE INDEX IF NOT EXISTS idx_versement_date_paiement ON versement(date_paiement);
CREATE INDEX IF NOT EXISTS idx_versement_annee_concernee ON versement(annee_concernee);

-- ========================================
-- Données d'exemple (optionnel)
-- ========================================
INSERT IGNORE INTO clients (nom, prenom, activite, annee, forme_juridique, regime_fiscal, honoraires_mois, montant, remaining_balance, phone, company) VALUES
('Benali', 'Ahmed', 'Commerce de détail', '2024', 'Individual', 'IFU', '15000', 180000, 180000, '0551123456', 'Benali Commerce'),
('Khelifi', 'Fatima', 'Services informatiques', '2024', 'SARL', 'Réel', '25000', 300000, 300000, '0661234567', 'InfoTech Solutions'),
('Mansouri', 'Mohamed', 'Restauration', '2024', 'Individual', 'IFU', '12000', 144000, 144000, '0771234568', 'Restaurant Le Palmier');

-- Ajouter quelques versements d'exemple
INSERT IGNORE INTO versement (client_id, montant, type, date_paiement, annee_concernee) VALUES
(1, 50000, 'Acompte', '2024-01-15', '2024'),
(1, 30000, 'Paiement partiel', '2024-02-15', '2024'),
(2, 100000, 'Acompte', '2024-01-20', '2024'),
(3, 72000, 'Solde', '2024-03-10', '2024');

-- Mettre à jour les montants restants après les versements d'exemple
UPDATE clients SET remaining_balance = 100000 WHERE id = 1; -- 180000 - 80000
UPDATE clients SET remaining_balance = 200000 WHERE id = 2; -- 300000 - 100000
UPDATE clients SET remaining_balance = 72000 WHERE id = 3;  -- 144000 - 72000

-- ========================================
-- Vues utiles (optionnel)
-- ========================================

-- Vue pour les statistiques clients
CREATE OR REPLACE VIEW client_stats AS
SELECT 
    c.id,
    c.nom,
    c.prenom,
    c.company,
    c.montant as montant_annuel,
    c.remaining_balance as montant_restant,
    COALESCE(SUM(v.montant), 0) as total_verse,
    COUNT(v.id) as nombre_versements,
    MAX(v.date_paiement) as dernier_versement
FROM clients c
LEFT JOIN versement v ON c.id = v.client_id
GROUP BY c.id, c.nom, c.prenom, c.company, c.montant, c.remaining_balance;

-- Vue pour les versements avec informations client
CREATE OR REPLACE VIEW versements_details AS
SELECT 
    v.id,
    v.client_id,
    CONCAT(c.nom, ' ', COALESCE(c.prenom, '')) as nom_client,
    c.company,
    v.montant,
    v.type,
    v.date_paiement,
    v.annee_concernee,
    v.created_at
FROM versement v
JOIN clients c ON v.client_id = c.id
ORDER BY v.date_paiement DESC;

-- ========================================
-- Procédures stockées utiles (optionnel)
-- ========================================

DELIMITER //

-- Procédure pour calculer le montant restant d'un client
CREATE PROCEDURE IF NOT EXISTS CalculateRemainingBalance(IN client_id INT)
BEGIN
    DECLARE annual_amount DECIMAL(15,2) DEFAULT 0;
    DECLARE total_versements DECIMAL(15,2) DEFAULT 0;
    DECLARE remaining DECIMAL(15,2) DEFAULT 0;
    
    -- Récupérer le montant annuel
    SELECT COALESCE(montant, 0) INTO annual_amount 
    FROM clients WHERE id = client_id;
    
    -- Calculer le total des versements
    SELECT COALESCE(SUM(montant), 0) INTO total_versements 
    FROM versement WHERE client_id = client_id;
    
    -- Calculer le montant restant
    SET remaining = annual_amount - total_versements;
    
    -- Mettre à jour le montant restant
    UPDATE clients 
    SET remaining_balance = remaining, updated_at = CURRENT_TIMESTAMP 
    WHERE id = client_id;
    
    SELECT remaining as montant_restant;
END //

-- Procédure pour obtenir les statistiques mensuelles
CREATE PROCEDURE IF NOT EXISTS GetMonthlyStats(IN target_year INT, IN target_month INT)
BEGIN
    SELECT 
        COUNT(DISTINCT v.client_id) as clients_actifs,
        COUNT(v.id) as nombre_versements,
        SUM(v.montant) as total_versements,
        AVG(v.montant) as versement_moyen
    FROM versement v
    WHERE YEAR(v.date_paiement) = target_year 
    AND MONTH(v.date_paiement) = target_month;
END //

DELIMITER ;

-- ========================================
-- Triggers pour maintenir la cohérence
-- ========================================

DELIMITER //

-- Trigger pour mettre à jour le montant restant après insertion d'un versement
CREATE TRIGGER IF NOT EXISTS after_versement_insert
AFTER INSERT ON versement
FOR EACH ROW
BEGIN
    UPDATE clients 
    SET remaining_balance = COALESCE(remaining_balance, montant) - NEW.montant,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.client_id;
END //

-- Trigger pour mettre à jour le montant restant après modification d'un versement
CREATE TRIGGER IF NOT EXISTS after_versement_update
AFTER UPDATE ON versement
FOR EACH ROW
BEGIN
    UPDATE clients 
    SET remaining_balance = remaining_balance + OLD.montant - NEW.montant,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.client_id;
END //

-- Trigger pour mettre à jour le montant restant après suppression d'un versement
CREATE TRIGGER IF NOT EXISTS after_versement_delete
AFTER DELETE ON versement
FOR EACH ROW
BEGIN
    UPDATE clients 
    SET remaining_balance = remaining_balance + OLD.montant,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = OLD.client_id;
END //

DELIMITER ;

-- ========================================
-- Affichage des informations de configuration
-- ========================================
SELECT 'Configuration terminée avec succès!' as status;
SELECT COUNT(*) as nombre_clients FROM clients;
SELECT COUNT(*) as nombre_versements FROM versement;
SELECT SUM(montant) as total_montants_annuels FROM clients;
SELECT SUM(montant) as total_versements FROM versement;

-- ========================================
-- Instructions finales
-- ========================================
/*
INSTRUCTIONS POST-INSTALLATION:

1. Vérifiez que toutes les tables ont été créées:
   SHOW TABLES;

2. Vérifiez les données d'exemple:
   SELECT * FROM clients;
   SELECT * FROM versement;

3. Testez les vues:
   SELECT * FROM client_stats;
   SELECT * FROM versements_details LIMIT 5;

4. Pour créer un utilisateur dédié à l'application:
   CREATE USER 'clientapp'@'localhost' IDENTIFIED BY 'motdepasse_securise';
   GRANT ALL PRIVILEGES ON client_management.* TO 'clientapp'@'localhost';
   FLUSH PRIVILEGES;

5. Pour sauvegarder la base de données:
   mysqldump -u root -p client_management > backup_client_management.sql

6. Pour restaurer la base de données:
   mysql -u root -p client_management < backup_client_management.sql
*/