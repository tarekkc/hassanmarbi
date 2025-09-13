package com.yourcompany.clientmanagement.controller;

import com.yourcompany.clientmanagement.dao.VersmentDAO;
import com.yourcompany.clientmanagement.dao.ClientDAO;
import com.yourcompany.clientmanagement.model.Versment;
import com.yourcompany.clientmanagement.model.Client;

import java.math.BigDecimal;
import java.util.List;

public class VersmentController {
    private VersmentDAO versmentDAO;
    private ClientDAO clientDAO;

    public VersmentController() {
        versmentDAO = new VersmentDAO();
        clientDAO = new ClientDAO();
    }

    // 🔄 1. Fetch all versments
    public List<Versment> fetchAllVersments() {
        return versmentDAO.getAllVersments();
    }

    // 🔄 2. Fetch versments by client ID
    public List<Versment> fetchVersmentsByClientId(int clientId) {
        return versmentDAO.getVersmentsByClientId(clientId);
    }

    // ➕ 3. Add a versment
    public int addVersment(Versment versment) {
        if (versment == null) {
            throw new IllegalArgumentException("Versment cannot be null");
        }
        if (versment.getClientId() <= 0) {
            throw new IllegalArgumentException("Valid client ID is required");
        }
        if (versment.getMontant() == null || versment.getMontant().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Valid amount is required");
        }

        // Insert the versment first
        int versmentId = versmentDAO.insertVersment(versment);
        
        if (versmentId > 0) {
            // Update client's annual amount by reducing the versment amount
            updateClientMontantAfterVersment(versment.getClientId(), versment.getMontant(), false);
        }
        
        return versmentId;
    }

    // ✏️ 4. Update a versment
    public boolean updateVersment(Versment versment) {
        if (versment == null) {
            throw new IllegalArgumentException("Versment cannot be null");
        }
        if (versment.getId() <= 0) {
            throw new IllegalArgumentException("Valid versment ID is required for update");
        }
        
        // Get the original versment to calculate the difference
        Versment originalVersment = versmentDAO.getVersmentById(versment.getId());
        if (originalVersment == null) {
            throw new IllegalArgumentException("Original versment not found");
        }
        
        boolean success = versmentDAO.updateVersment(versment);
        
        if (success) {
            // Calculate the difference and update client's montant
            BigDecimal difference = versment.getMontant().subtract(originalVersment.getMontant());
            if (difference.compareTo(BigDecimal.ZERO) != 0) {
                // If difference is positive, we need to reduce more from client's montant
                // If difference is negative, we need to add back to client's montant
                updateClientMontantAfterVersment(versment.getClientId(), difference, false);
            }
        }
        
        return success;
    }

    // ❌ 5. Delete a versment by ID
    public boolean deleteVersment(int versmentId) {
        if (versmentId <= 0) {
            throw new IllegalArgumentException("Valid versment ID is required");
        }
        
        // Get the versment before deleting to restore the client's montant
        Versment versment = versmentDAO.getVersmentById(versmentId);
        if (versment == null) {
            throw new IllegalArgumentException("Versment not found");
        }
        
        boolean success = versmentDAO.deleteVersmentById(versmentId);
        
        if (success) {
            // Add back the versment amount to client's montant
            updateClientMontantAfterVersment(versment.getClientId(), versment.getMontant(), true);
        }
        
        return success;
    }

    // 🔎 6. Get versment by ID
    public Versment getVersmentById(int id) {
        return versmentDAO.getVersmentById(id);
    }

    // 💰 7. Get total versments amount by client ID
    public BigDecimal getTotalVersmentsByClientId(int clientId) {
        return versmentDAO.getTotalVersmentsByClientId(clientId);
    }

    // 🔄 8. Update client's montant after versment operations
    private void updateClientMontantAfterVersment(int clientId, BigDecimal versmentAmount, boolean isRestore) {
        try {
            Client client = clientDAO.getClientById(clientId);
            if (client != null && client.getMontant() != null) {
                BigDecimal currentMontant = BigDecimal.valueOf(client.getMontant());
                BigDecimal newMontant;
                
                if (isRestore) {
                    // Restore: add back the versment amount
                    newMontant = currentMontant.add(versmentAmount);
                } else {
                    // Reduce: subtract the versment amount
                    newMontant = currentMontant.subtract(versmentAmount);
                    // Ensure montant doesn't go below zero
                    if (newMontant.compareTo(BigDecimal.ZERO) < 0) {
                        newMontant = BigDecimal.ZERO;
                    }
                }
                
                client.setMontant(newMontant.doubleValue());
                clientDAO.updateClient(client);
                
                System.out.println("Updated client " + clientId + " montant from " + 
                    currentMontant + " to " + newMontant + " (versment: " + versmentAmount + 
                    ", restore: " + isRestore + ")");
            }
        } catch (Exception e) {
            System.err.println("Error updating client montant after versment operation: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // 💰 9. Get remaining amount for a client (montant - total versments)
    public BigDecimal getRemainingAmountForClient(int clientId) {
        try {
            Client client = clientDAO.getClientById(clientId);
            if (client == null || client.getMontant() == null) {
                return BigDecimal.ZERO;
            }
            
            BigDecimal totalMontant = BigDecimal.valueOf(client.getMontant());
            BigDecimal totalVersments = getTotalVersmentsByClientId(clientId);
            
            BigDecimal remaining = totalMontant.subtract(totalVersments);
            return remaining.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : remaining;
        } catch (Exception e) {
            System.err.println("Error calculating remaining amount for client: " + e.getMessage());
            return BigDecimal.ZERO;
        }
    }
}