import java.awt.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableModel;

// Main application class for Prison Management System
// Connects to MySQL database using JDBC

public class PrisonManagementApp extends JFrame {
    static {
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
    } catch (ClassNotFoundException e) {
        e.printStackTrace();
    }
}

    // database connection details
    private static final String DB_URL = "jdbc:mysql://localhost:3306/PrisonManagementSystem?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "Aymen@30";

    // all table names in our database
    private final String[] TABLES = {
        "PRISON",
        "BLOCK",
        "CELL",
        "STAFF",
        "INMATE",
        "SENTENCE",
        "VISITOR",
        "VISIT",
        "MEDICAL_RECORD",
        "DISCIPLINARY_RECORD",
        "TRANSFER",
        "PAROLE"
    };

    // UI components used across methods
    private JComboBox<String> tableComboBox;
    private JTextField searchField;
    private JTable table;
    private DefaultTableModel tableModel;

    private JTextArea sqlArea;
    private JTable sqlResultTable;
    private DefaultTableModel sqlResultModel;

    private JLabel statusLabel;
    private JPanel dashboardPanel;

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            PrisonManagementApp app = new PrisonManagementApp();
            app.setVisible(true);
        });
    }

    // constructor - sets up the whole window
    public PrisonManagementApp() {
        setTitle("Prison Management System");
        setSize(1200, 720);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        add(createHeader(), BorderLayout.NORTH);

        // three tabs: dashboard, table viewer, custom sql
        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Dashboard", createDashboardTab());
        tabs.addTab("Table Manager", createTableManagerTab());
        tabs.addTab("Custom SQL", createSqlTab());

        add(tabs, BorderLayout.CENTER);

        // check db connection on startup
        testConnection();
        loadDashboard();
        loadSelectedTable();
    }

    // opens a new connection each time (simple approach)
    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }

    private void testConnection() {
        try (Connection conn = getConnection()) {
            statusLabel.setText("  Connected to PrisonManagementSystem");
            statusLabel.setForeground(new Color(40, 170, 90));
        } catch (SQLException e) {
            statusLabel.setText("  Connection failed: " + e.getMessage());
            statusLabel.setForeground(Color.RED);
        }
    }


    //  HEADER

    private JPanel createHeader() {
        JPanel header = new JPanel(new BorderLayout());
        header.setBackground(new Color(25, 35, 50));
        header.setBorder(new EmptyBorder(18, 25, 18, 25));

        JLabel title = new JLabel("Prison Management System");
        title.setForeground(Color.WHITE);
        title.setFont(new Font("Arial", Font.BOLD, 26));

        JPanel titlePanel = new JPanel(new GridLayout(1, 1));
        titlePanel.setOpaque(false);
        titlePanel.add(title);

        statusLabel = new JLabel("Checking connection...");
        statusLabel.setForeground(Color.WHITE);
        statusLabel.setFont(new Font("Arial", Font.BOLD, 13));

        header.add(titlePanel, BorderLayout.WEST);
        header.add(statusLabel, BorderLayout.EAST);

        return header;
    }


    //  DASHBOARD TAB

    private JPanel createDashboardTab() {
        JPanel main = new JPanel(new BorderLayout());
        main.setBorder(new EmptyBorder(25, 25, 25, 25));

        JLabel heading = new JLabel("Dashboard Overview");
        heading.setFont(new Font("Arial", Font.BOLD, 24));

        // 2 rows, 3 cols grid for stat cards
        dashboardPanel = new JPanel(new GridLayout(2, 3, 20, 20));
        dashboardPanel.setBorder(new EmptyBorder(25, 0, 0, 0));

        JButton refreshBtn = new JButton("Refresh Dashboard");
        refreshBtn.addActionListener(e -> loadDashboard());

        JPanel bottom = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        bottom.add(refreshBtn);

        main.add(heading, BorderLayout.NORTH);
        main.add(dashboardPanel, BorderLayout.CENTER);
        main.add(bottom, BorderLayout.SOUTH);

        return main;
    }

    private void loadDashboard() {
        if (dashboardPanel == null) return;

        dashboardPanel.removeAll();

        // each card runs one COUNT query
        addCard("Total Prisons",  "SELECT COUNT(*) FROM PRISON");
        addCard("Total Blocks",   "SELECT COUNT(*) FROM BLOCK");
        addCard("Total Cells",    "SELECT COUNT(*) FROM CELL");
        addCard("Total Staff",    "SELECT COUNT(*) FROM STAFF");
        addCard("Total Inmates",  "SELECT COUNT(*) FROM INMATE");
        addCard("Active Inmates", "SELECT COUNT(*) FROM INMATE WHERE status = 'Active'");

        dashboardPanel.revalidate();
        dashboardPanel.repaint();
    }

    // creates one stat card and runs the sql to get the number
    private void addCard(String title, String sql) {
        String value = "0";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                value = rs.getString(1);
            }

        } catch (SQLException e) {
            value = "Error";
        }

        JPanel card = new JPanel(new BorderLayout());
        card.setBackground(Color.WHITE);
        card.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(new Color(220, 220, 220)),
            new EmptyBorder(25, 25, 25, 25)
        ));

        JLabel valueLabel = new JLabel(value);
        valueLabel.setFont(new Font("Arial", Font.BOLD, 34));
        valueLabel.setForeground(new Color(30, 90, 160));

        JLabel titleLabel = new JLabel(title);
        titleLabel.setFont(new Font("Arial", Font.BOLD, 16));

        card.add(valueLabel, BorderLayout.CENTER);
        card.add(titleLabel, BorderLayout.SOUTH);

        dashboardPanel.add(card);
    }

    //  TABLE MANAGER TAB

    private JPanel createTableManagerTab() {
        JPanel main = new JPanel(new BorderLayout());
        main.setBorder(new EmptyBorder(15, 15, 15, 15));

        JPanel controls = new JPanel(new FlowLayout(FlowLayout.LEFT));

        tableComboBox = new JComboBox<>(TABLES);
        tableComboBox.addActionListener(e -> loadSelectedTable());

        searchField = new JTextField(18);

        JButton searchBtn = new JButton("Search");
        searchBtn.addActionListener(e -> loadSelectedTable());

        JButton refreshBtn = new JButton("Refresh");
        refreshBtn.addActionListener(e -> {
            searchField.setText("");
            loadSelectedTable();
        });

        JButton addBtn    = new JButton("Add");
        JButton updateBtn = new JButton("Update");
        JButton deleteBtn = new JButton("Delete");

        addBtn.addActionListener(e    -> addRecord());
        updateBtn.addActionListener(e -> updateRecord());
        deleteBtn.addActionListener(e -> deleteRecord());

        controls.add(new JLabel("Table:"));
        controls.add(tableComboBox);
        controls.add(new JLabel("Search:"));
        controls.add(searchField);
        controls.add(searchBtn);
        controls.add(refreshBtn);
        controls.add(addBtn);
        controls.add(updateBtn);
        controls.add(deleteBtn);

        tableModel = new DefaultTableModel();
        table = new JTable(tableModel);
        table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
        table.setRowHeight(24);

        main.add(controls, BorderLayout.NORTH);
        main.add(new JScrollPane(table), BorderLayout.CENTER);

        return main;
    }

    // loads data from selected table, applies search filter if any
    private void loadSelectedTable() {
        if (tableComboBox == null) return;

        String tableName = tableComboBox.getSelectedItem().toString();
        String keyword   = searchField.getText().trim();

        try {
            List<ColumnInfo> columns = getColumns(tableName);

            StringBuilder sql = new StringBuilder("SELECT * FROM " + tableName);

            // if search keyword is entered, search across all columns
            if (!keyword.isEmpty()) {
                sql.append(" WHERE ");
                for (int i = 0; i < columns.size(); i++) {
                    if (i > 0) sql.append(" OR ");
                    sql.append("CAST(").append(columns.get(i).name).append(" AS CHAR) LIKE ?");
                }
            }

            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql.toString())) {

                if (!keyword.isEmpty()) {
                    for (int i = 1; i <= columns.size(); i++) {
                        ps.setString(i, "%" + keyword + "%");
                    }
                }

                try (ResultSet rs = ps.executeQuery()) {
                    fillTable(rs, tableModel);
                }
            }

        } catch (SQLException e) {
            showError("Failed to load table: " + e.getMessage());
        }
    }

    private void addRecord() {
        String tableName = tableComboBox.getSelectedItem().toString();

        try {
            List<ColumnInfo> columns = getColumns(tableName);
            Map<String, String> values = showRecordDialog("Add Record", columns, null, null);

            if (values == null) return; // user cancelled

            StringBuilder colNames     = new StringBuilder();
            StringBuilder placeholders = new StringBuilder();

            for (int i = 0; i < columns.size(); i++) {
                if (i > 0) {
                    colNames.append(", ");
                    placeholders.append(", ");
                }
                colNames.append(columns.get(i).name);
                placeholders.append("?");
            }

            String sql = "INSERT INTO " + tableName + " (" + colNames + ") VALUES (" + placeholders + ")";

            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {

                for (int i = 0; i < columns.size(); i++) {
                    setValue(ps, i + 1, columns.get(i), values.get(columns.get(i).name));
                }
                ps.executeUpdate();
            }

            JOptionPane.showMessageDialog(this, "Record added successfully.");
            loadSelectedTable();
            loadDashboard();

        } catch (Exception e) {
            showError("Add failed: " + e.getMessage());
        }
    }

    private void updateRecord() {
        int selectedRow = table.getSelectedRow();

        if (selectedRow == -1) {
            JOptionPane.showMessageDialog(this, "Please select a row first.");
            return;
        }

        String tableName = tableComboBox.getSelectedItem().toString();
        int modelRow     = table.convertRowIndexToModel(selectedRow);

        try {
            String primaryKey = getPrimaryKey(tableName);

            if (primaryKey == null) {
                showError("Could not find primary key.");
                return;
            }

            List<ColumnInfo> columns = getColumns(tableName);
            Map<String, String> currentValues = new LinkedHashMap<>();

            // fill current values from selected row
            for (int i = 0; i < tableModel.getColumnCount(); i++) {
                String colName = tableModel.getColumnName(i);
                Object value   = tableModel.getValueAt(modelRow, i);
                currentValues.put(colName, value == null ? "" : value.toString());
            }

            String pkValue = currentValues.get(primaryKey);
            Map<String, String> newValues = showRecordDialog("Update Record", columns, currentValues, primaryKey);

            if (newValues == null) return;

            StringBuilder sql = new StringBuilder("UPDATE " + tableName + " SET ");
            boolean first = true;

            for (ColumnInfo col : columns) {
                if (col.name.equalsIgnoreCase(primaryKey)) continue;
                if (!first) sql.append(", ");
                sql.append(col.name).append(" = ?");
                first = false;
            }

            sql.append(" WHERE ").append(primaryKey).append(" = ?");

            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql.toString())) {

                int index = 1;
                for (ColumnInfo col : columns) {
                    if (col.name.equalsIgnoreCase(primaryKey)) continue;
                    setValue(ps, index, col, newValues.get(col.name));
                    index++;
                }
                setValue(ps, index, findColumn(columns, primaryKey), pkValue);
                ps.executeUpdate();
            }

            JOptionPane.showMessageDialog(this, "Record updated successfully.");
            loadSelectedTable();
            loadDashboard();

        } catch (Exception e) {
            showError("Update failed: " + e.getMessage());
        }
    }

    private void deleteRecord() {
        int selectedRow = table.getSelectedRow();

        if (selectedRow == -1) {
            JOptionPane.showMessageDialog(this, "Please select a row first.");
            return;
        }

        // confirm before deleting
        int confirm = JOptionPane.showConfirmDialog(
            this,
            "Are you sure you want to delete this record?",
            "Confirm Delete",
            JOptionPane.YES_NO_OPTION
        );

        if (confirm != JOptionPane.YES_OPTION) return;

        String tableName = tableComboBox.getSelectedItem().toString();
        int modelRow     = table.convertRowIndexToModel(selectedRow);

        try {
            String primaryKey = getPrimaryKey(tableName);

            if (primaryKey == null) {
                showError("Could not find primary key.");
                return;
            }

            int pkIndex    = tableModel.findColumn(primaryKey);
            String pkValue = tableModel.getValueAt(modelRow, pkIndex).toString();

            List<ColumnInfo> columns = getColumns(tableName);
            ColumnInfo pkColumn = findColumn(columns, primaryKey);

            String sql = "DELETE FROM " + tableName + " WHERE " + primaryKey + " = ?";

            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {

                setValue(ps, 1, pkColumn, pkValue);
                ps.executeUpdate();
            }

            JOptionPane.showMessageDialog(this, "Record deleted successfully.");
            loadSelectedTable();
            loadDashboard();

        } catch (Exception e) {
            showError("Delete failed. This record may be linked to another table.\n\n" + e.getMessage());
        }
    }

    //  CUSTOM SQL TAB

    private JPanel createSqlTab() {
        JPanel main = new JPanel(new BorderLayout());
        main.setBorder(new EmptyBorder(15, 15, 15, 15));

        sqlArea = new JTextArea(6, 80);
        sqlArea.setFont(new Font("Monospaced", Font.PLAIN, 14));
        sqlArea.setText("SELECT * FROM INMATE;");

        JButton runBtn = new JButton("Run SQL");
        runBtn.addActionListener(e -> runCustomSql());

        JPanel top = new JPanel(new BorderLayout());
        top.add(new JScrollPane(sqlArea), BorderLayout.CENTER);
        top.add(runBtn, BorderLayout.EAST);

        sqlResultModel = new DefaultTableModel();
        sqlResultTable = new JTable(sqlResultModel);
        sqlResultTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
        sqlResultTable.setRowHeight(24);

        main.add(top, BorderLayout.NORTH);
        main.add(new JScrollPane(sqlResultTable), BorderLayout.CENTER);

        return main;
    }

    private void runCustomSql() {
        String sql = sqlArea.getText().trim();

        if (sql.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Please enter a SQL query first.");
            return;
        }

        try (Connection conn = getConnection();
             Statement st = conn.createStatement()) {

            boolean hasResult = st.execute(sql);

            if (hasResult) {
                // SELECT query - show results in table
                try (ResultSet rs = st.getResultSet()) {
                    fillTable(rs, sqlResultModel);
                }
            } else {
                // INSERT / UPDATE / DELETE - show rows affected
                int rows = st.getUpdateCount();
                JOptionPane.showMessageDialog(this, rows + " row(s) affected.");
                loadSelectedTable();
                loadDashboard();
            }

        } catch (SQLException e) {
            showError("Query failed: " + e.getMessage());
        }
    }

    //  HELPER METHODS

    // fills a JTable model from a ResultSet
    private void fillTable(ResultSet rs, DefaultTableModel model) throws SQLException {
        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();

        model.setRowCount(0);
        model.setColumnCount(0);

        for (int i = 1; i <= columnCount; i++) {
            model.addColumn(meta.getColumnLabel(i));
        }

        while (rs.next()) {
            Object[] row = new Object[columnCount];
            for (int i = 1; i <= columnCount; i++) {
                row[i - 1] = rs.getObject(i);
            }
            model.addRow(row);
        }
    }

    // uses DatabaseMetaData to get column info dynamically
    private List<ColumnInfo> getColumns(String tableName) throws SQLException {
        List<ColumnInfo> columns = new ArrayList<>();

        try (Connection conn = getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            try (ResultSet rs = meta.getColumns(conn.getCatalog(), null, tableName, null)) {
                while (rs.next()) {
                    columns.add(new ColumnInfo(
                        rs.getString("COLUMN_NAME"),
                        rs.getInt("DATA_TYPE"),
                        rs.getString("TYPE_NAME"),
                        rs.getInt("NULLABLE") == DatabaseMetaData.columnNullable
                    ));
                }
            }
        }

        return columns;
    }

    private String getPrimaryKey(String tableName) throws SQLException {
        try (Connection conn = getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            try (ResultSet rs = meta.getPrimaryKeys(conn.getCatalog(), null, tableName)) {
                if (rs.next()) {
                    return rs.getString("COLUMN_NAME");
                }
            }
        }
        return null;
    }

    private ColumnInfo findColumn(List<ColumnInfo> columns, String name) {
        for (ColumnInfo col : columns) {
            if (col.name.equalsIgnoreCase(name)) return col;
        }
        return null;
    }

    // sets PreparedStatement parameter based on SQL type
    private void setValue(PreparedStatement ps, int index, ColumnInfo col, String value) throws SQLException {
        if (value == null || value.trim().isEmpty()) {
            if (col.nullable) {
                ps.setNull(index, col.sqlType);
                return;
            }
        }

        String v = (value == null) ? "" : value.trim();

        switch (col.sqlType) {
            case Types.INTEGER:
            case Types.SMALLINT:
            case Types.TINYINT:
            case Types.BIGINT:
                ps.setLong(index, Long.parseLong(v));
                break;

            case Types.FLOAT:
            case Types.DOUBLE:
            case Types.REAL:
            case Types.DECIMAL:
            case Types.NUMERIC:
                ps.setDouble(index, Double.parseDouble(v));
                break;

            case Types.DATE:
                ps.setDate(index, java.sql.Date.valueOf(v));
                break;

            default:
                ps.setString(index, v);
                break;
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, String> showRecordDialog(
        String title,
        List<ColumnInfo> columns,
        Map<String, String> existingValues,
        String disabledColumn
    ) {
        JDialog dialog = new JDialog(this, title, true);
        dialog.setSize(520, 520);
        dialog.setLocationRelativeTo(this);
        dialog.setLayout(new BorderLayout());

        JPanel form = new JPanel(new GridBagLayout());
        form.setBorder(new EmptyBorder(15, 15, 15, 15));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(6, 6, 6, 6);
        gbc.fill   = GridBagConstraints.HORIZONTAL;

        Map<String, JTextField> fields = new LinkedHashMap<>();

        for (int i = 0; i < columns.size(); i++) {
            ColumnInfo col = columns.get(i);

            gbc.gridx   = 0;
            gbc.gridy   = i;
            gbc.weightx = 0.3;
            form.add(new JLabel(col.name + " (" + col.typeName + ")"), gbc);

            gbc.gridx   = 1;
            gbc.weightx = 0.7;

            JTextField field = new JTextField();

            // pre-fill values if updating
            if (existingValues != null && existingValues.containsKey(col.name)) {
                field.setText(existingValues.get(col.name));
            }

            // disable PK field when updating
            if (disabledColumn != null && col.name.equalsIgnoreCase(disabledColumn)) {
                field.setEnabled(false);
            }

            fields.put(col.name, field);
            form.add(field, gbc);
        }

        final Map<String, String>[] result = new Map[]{ null };

        JButton saveBtn = new JButton("Save");
        saveBtn.addActionListener(e -> {
            Map<String, String> values = new LinkedHashMap<>();
            for (Map.Entry<String, JTextField> entry : fields.entrySet()) {
                values.put(entry.getKey(), entry.getValue().getText());
            }
            result[0] = values;
            dialog.dispose();
        });

        JButton cancelBtn = new JButton("Cancel");
        cancelBtn.addActionListener(e -> dialog.dispose());

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttons.add(saveBtn);
        buttons.add(cancelBtn);

        dialog.add(new JScrollPane(form), BorderLayout.CENTER);
        dialog.add(buttons, BorderLayout.SOUTH);
        dialog.setVisible(true);

        return result[0];
    }

    private void showError(String msg) {
        JOptionPane.showMessageDialog(this, msg, "Error", JOptionPane.ERROR_MESSAGE);
    }

    // simple inner class to hold column metadata
    private static class ColumnInfo {
        String  name;
        int     sqlType;
        String  typeName;
        boolean nullable;

        ColumnInfo(String name, int sqlType, String typeName, boolean nullable) {
            this.name     = name;
            this.sqlType  = sqlType;
            this.typeName = typeName;
            this.nullable = nullable;
        }
    }
}