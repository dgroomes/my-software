package dgroomes;

import com.intellij.openapi.project.Project;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;

public class MyWindow {

    private static final Logger log = LoggerFactory.getLogger(MyWindow.class);
    private final ProjectDetailsService projectDetailsService;
    private JPanel root;
    private JButton copyButton;
    private JButton saveToFileButton;

    public MyWindow(Project project) {
        this.projectDetailsService = project.getService(ProjectDetailsService.class);
        copyButton.addActionListener(e1 -> {
            log.info("Copy button clicked.");
            projectDetailsService.copyProjectDetailsToClipboard();
        });
        saveToFileButton.addActionListener(e -> {
            log.info("Save button clicked.");
            projectDetailsService.saveProjectDetailsToFile();
        });
    }

    public JPanel getRootElement() {
        return root;
    }
}
