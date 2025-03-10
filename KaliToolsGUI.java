import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;

public class KaliToolsGUI extends JFrame {
    private JTextField targetUrlField;
    private JTextArea outputArea;
    private JButton startButton;
    private JButton sqlmapButton;
    private JButton addTamperButton;
    private JButton quitButton;
    private String customTamperScripts = "";

    public KaliToolsGUI() {
        setTitle("Kali Linux Tools GUI");
        setSize(800, 600);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        targetUrlField = new JTextField(50);
        outputArea = new JTextArea(20, 70);
        outputArea.setEditable(false);
        outputArea.setLineWrap(true);
        outputArea.setWrapStyleWord(true);
        JScrollPane scrollPane = new JScrollPane(outputArea);

        startButton = new JButton("Start Analysis");
        sqlmapButton = new JButton("SQLMap Terminal");
        addTamperButton = new JButton("Add Tamper Script");
        quitButton = new JButton("Quit");

        JPanel panel = new JPanel();
        panel.add(new JLabel("Target URL:"));
        panel.add(targetUrlField);
        panel.add(startButton);
        panel.add(sqlmapButton);
        panel.add(addTamperButton);
        panel.add(quitButton);

        setLayout(new BorderLayout());
        add(panel, BorderLayout.NORTH);
        add(scrollPane, BorderLayout.CENTER);

        startButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                String targetUrl = targetUrlField.getText();
                if (targetUrl.isEmpty()) {
                    JOptionPane.showMessageDialog(null, "Please enter a target URL.", "Input Error", JOptionPane.WARNING_MESSAGE);
                    return;
                }
                outputArea.append("Starting analysis for: " + targetUrl + "\n");
                runCommand("./enhanced_kali_burp_zap_jsql_tool.sh " + targetUrl);
            }
        });

        sqlmapButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                String targetUrl = targetUrlField.getText();
                if (targetUrl.isEmpty()) {
                    JOptionPane.showMessageDialog(null, "Please enter a target URL.", "Input Error", JOptionPane.WARNING_MESSAGE);
                    return;
                }
                openSqlmapTerminal(targetUrl);
            }
        });

        addTamperButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                addCustomTamperScript();
            }
        });

        quitButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                System.exit(0);
            }
        });
    }

    private void runCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(command);
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                outputArea.append(line + "\n");
            }
            reader.close();
            process.waitFor();
        } catch (Exception e) {
            e.printStackTrace();
            outputArea.append("Error running command: " + e.getMessage() + "\n");
        }
    }

    private void openSqlmapTerminal(String targetUrl) {
        try {
            String user = System.getProperty("user.name");
            String tamperScripts = "";
            if (user.equals("thegreyghost")) {
                tamperScripts = customTamperScripts.isEmpty() ? "--tamper=space2comment,between,randomcase" : "--tamper=" + customTamperScripts;
            }
            String[] command = { "gnome-terminal", "--", "bash", "-c", "sqlmap -u " + targetUrl + " --batch " + tamperScripts + " --level=5 --risk=3 --identify-waf --random-agent; exec bash" };
            Runtime.getRuntime().exec(command);
        } catch (Exception e) {
            e.printStackTrace();
            outputArea.append("Error opening SQLMap terminal: " + e.getMessage() + "\n");
        }
    }

    private void addCustomTamperScript() {
        String scriptName = JOptionPane.showInputDialog("Enter the name of the custom tamper script:");
        if (scriptName != null && !scriptName.trim().isEmpty()) {
            customTamperScripts += scriptName + ",";
            JOptionPane.showMessageDialog(null, "Custom tamper script added: " + scriptName);
        }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                new KaliToolsGUI().setVisible(true);
            }
        });
    }
}