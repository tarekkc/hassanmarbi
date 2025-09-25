getPhone(), c.getCreatedAt()
        };
    }

    private void refreshClientTable() {
        loadClientData();
    }
    
    private void updateColumnHeadersWithTotals() {
        try {
            // Calculate totals from current table data
            int totalClients = tableModel.getRowCount();
            double totalHonorairesMois = 0.0;
            double totalMontantAnnual = 0.0;
            double totalRemainingBalance = 0.0;
            
            for (int row = 0; row < tableModel.getRowCount(); row++) {
                // Honoraires/Mois (column index 10 in model)
                Object honorairesObj = tableModel.getValueAt(row, COL_HONORAIRES_MOIS);
                if (honorairesObj != null && !honorairesObj.toString().isEmpty()) {
                    try {
                        totalHonorairesMois += Double.parseDouble(honorairesObj.toString());
                    } catch (NumberFormatException e) {
                        // Skip invalid values
                    }
                }
                
                // Montant Annual (column index 11 in model)
                Object montantObj = tableModel.getValueAt(row, COL_MONTANT);
                if (montantObj != null) {
                    if (montantObj instanceof Double) {
                        totalMontantAnnual += (Double) montantObj;
                    } else {
                        try {
                            totalMontantAnnual += Double.parseDouble(montantObj.toString());
                        } catch (NumberFormatException e) {
                            // Skip invalid values
                        }
                    }
                }
                
                // Remaining Balance (column index 12 in model) - extract numeric value from "X DA" format
                Object remainingObj = tableModel.getValueAt(row, COL_MONTANT + 1);
                if (remainingObj != null) {
                    String remainingStr = remainingObj.toString();
                    if (remainingStr.contains(" DA")) {
                        try {
                            String numericPart = remainingStr.replace(" DA", "").trim();
                            totalRemainingBalance += Double.parseDouble(numericPart);
                        } catch (NumberFormatException e) {
                            // Skip invalid values
                        }
                    }
                }
            }
            
            // Update column headers with totals
            TableColumnModel columnModel = clientTable.getColumnModel();
            
            // Update "Nom" column header with total clients (visible column index 0, since ID is hidden)
            TableColumn nomColumn = columnModel.getColumn(0);
            nomColumn.setHeaderValue("Nom (Total: " + totalClients + " clients)");
            
            // Update "Honoraires/Mois" column header (visible column index 9, since ID is hidden)
            TableColumn honorairesColumn = columnModel.getColumn(9);
            honorairesColumn.setHeaderValue("Honoraires/Mois (Total: " + String.format("%.2f", totalHonorairesMois) + " DA)");
            
            // Update "Montant Annual" column header (visible column index 10, since ID is hidden)
            TableColumn montantColumn = columnModel.getColumn(10);
            montantColumn.setHeaderValue("Montant Annual (Total: " + String.format("%.2f", totalMontantAnnual) + " DA)");
            
            // Update "Montant Restant" column header (visible column index 11, since ID is hidden)
            TableColumn remainingColumn = columnModel.getColumn(11);
            remainingColumn.setHeaderValue("Montant Restant (Total: " + String.format("%.2f", totalRemainingBalance) + " DA)");
            
            // Refresh the table header
            clientTable.getTableHeader().repaint();
            
        } catch (Exception e) {
            System.err.println("Error updating column headers with totals: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void restoreAllColumns() {
        TableColumnModel columnModel = clientTable.getColumnModel();
        for (int i = 0; i < columnModel.getColumnCount(); i++) {
            TableColumn column = columnModel.getColumn(i);
            if (column.getWidth() == 0) {
                // Restore to default width
                column.setPreferredWidth(100);
                column.setMinWidth(15);
                column.setMaxWidth(Integer.MAX_VALUE);
            }
        }
    }

    private void showAddDialog() {
        ClientDialog dialog = new ClientDialog(this, "Ajouter Client", null);
        dialog.setVisible(true);
        if (dialog.isConfirmed()) {
            Client newClient = dialog.getClient();
            try {
                int result = controller.addClient(newClient);
                if (result > 0) {
                    refreshClientTable();
                    JOptionPane.showMessageDialog(this, "Client ajouté avec succès! ID: " + result);
                } else {
                    JOptionPane.showMessageDialog(this, "Erreur lors de l'ajout du client", "Erreur",
                            JOptionPane.ERROR_MESSAGE);
                }
            } catch (Exception e) {
                e.printStackTrace();
                JOptionPane.showMessageDialog(this, "Erreur lors de l'ajout: " + e.getMessage(), "Erreur",
                        JOptionPane.ERROR_MESSAGE);
            }
        }
    }


    private void refreshRemainingBalances() {
    SwingWorker<Void, Void> worker = new SwingWorker<>() {
        @Override
        protected Void doInBackground() {
            for (int row = 0; row < tableModel.getRowCount(); row++) {
                int clientId = (Integer) tableModel.getValueAt(row, COL_ID);
                Client client = controller.getClientById(clientId);
                if (client != null) {
                    Object[] newRowData = convertClientToRow(client);
                    final int finalRow = row;
                    SwingUtilities.invokeLater(() -> {
                        // Update only the remaining balance column (column 12)
                        tableModel.setValueAt(newRowData[12], finalRow, 12);
                    });
                }
            }
            return null;
        }
        
        @Override
        protected void done() {
            clientTable.repaint();
        }
    };
    worker.execute();
}

    private void showEditDialog() {
        int selectedRow = clientTable.getSelectedRow();
        if (selectedRow == -1) {
            JOptionPane.showMessageDialog(this, "Veuillez sélectionner un client", "Avertissement",
                    JOptionPane.WARNING_MESSAGE);
            return;
        }

        try {
            int modelRow = clientTable.convertRowIndexToModel(selectedRow);
            int clientId = (Integer) tableModel.getValueAt(modelRow, COL_ID);
            Client clientToEdit = controller.getClientById(clientId);

            if (clientToEdit != null) {
                ClientDialog dialog = new ClientDialog(this, "Modifier Client", clientToEdit);
                dialog.setVisible(true);
                if (dialog.isConfirmed()) {
                    Client updatedClient = dialog.getClient();
                    if (controller.updateClient(updatedClient)) {
                        // Update just this row instead of refreshing the whole table
                        updateClientRowInTable(updatedClient);
                        JOptionPane.showMessageDialog(this, "Client modifié avec succès!");
                    } else {
                        JOptionPane.showMessageDialog(this, "Erreur lors de la modification", "Erreur",
                                JOptionPane.ERROR_MESSAGE);
                    }
                }
            } else {
                JOptionPane.showMessageDialog(this, "Client non trouvé", "Erreur", JOptionPane.ERROR_MESSAGE);
            }
        } catch (Exception e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(this, "Erreur lors de la modification: " + e.getMessage(), "Erreur",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private void deleteClient() {
        int selectedRow = clientTable.getSelectedRow();
        if (selectedRow == -1) {
            JOptionPane.showMessageDialog(this, "Veuillez sélectionner un client", "Avertissement",
                    JOptionPane.WARNING_MESSAGE);
            return;
        }

        int confirm = JOptionPane.showConfirmDialog(
                this,
                "Êtes-vous sûr de vouloir supprimer ce client?\nCette action supprimera également tous ses versements.",
                "Confirmation",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            try {
                int modelRow = clientTable.convertRowIndexToModel(selectedRow);
                int clientId = (Integer) tableModel.getValueAt(modelRow, COL_ID);

                if (controller.deleteClient(clientId)) {
                    refreshClientTable();
                    JOptionPane.showMessageDialog(this, "Client supprimé avec succès!");
                } else {
                    JOptionPane.showMessageDialog(this, "Erreur lors de la suppression", "Erreur",
                            JOptionPane.ERROR_MESSAGE);
                }
            } catch (Exception e) {
                e.printStackTrace();
                JOptionPane.showMessageDialog(this, "Erreur lors de la suppression: " + e.getMessage(), "Erreur",
                        JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                new ClientForm().setVisible(true);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }
}