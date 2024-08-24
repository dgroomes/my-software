package dgroomes;

import com.intellij.openapi.Disposable;
import com.intellij.openapi.fileEditor.FileEditorManager;
import com.intellij.openapi.fileEditor.FileEditorManagerListener;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.util.messages.MessageBusConnection;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import java.awt.event.ActionEvent;

/**
 * This is a GUI component and is controlled by some framework magic. That explains why some of the instance fields
 * aren't initialized in the constructor. At least, they aren't set in the constructor in the way that the code is
 * authored. I think at build-time, there is codegen that combines the '.form' file and the component class into a new
 * class file which must set the instance fields.
 * <p>
 * Note: why is this class written in Java instead of Kotlin? I think I was having trouble with the '.form' components
 * working with Kotlin but that was a long time ago. I can stick with Java here and keep other logic, services, etc. in
 * Kotlin. Perfectly fine.
 */
public class MyWindow implements Disposable {

    private static final Logger log = LoggerFactory.getLogger(MyWindow.class);
    private final Project project;
    private final CopyOpenTabsService copyOpenTabsService;
    private JPanel root;
    private JList<String> openFiles;
    private JButton copyButton;
    private final MessageBusConnection messageBusConnection;


    public MyWindow(Project project) {
        this.project = project;
        this.copyOpenTabsService = project.getService(CopyOpenTabsService.class);
        copyButton.addActionListener(this::handleCopyButtonClick);

        // Initialize the list of open files
        updateOpenFilesList();

        // Set up listener for file editor changes
        messageBusConnection = project.getMessageBus().connect();
        messageBusConnection.subscribe(FileEditorManagerListener.FILE_EDITOR_MANAGER, new FileEditorManagerListener() {
            @Override
            public void fileOpened(@NotNull FileEditorManager source, @NotNull VirtualFile file) {
                log.info("File opened: {}", file.getName());
                updateOpenFilesList();
            }

            @Override
            public void fileClosed(@NotNull FileEditorManager source, @NotNull VirtualFile file) {
                log.info("File closed: {}", file.getName());
                updateOpenFilesList();
            }
        });
    }

    private void handleCopyButtonClick(ActionEvent e) {
        log.info("Copy button clicked.");
        copyOpenTabsService.copyOpenTabNames();
    }

    private void updateOpenFilesList() {
        var fileEditorManager = FileEditorManager.getInstance(project);
        var listModel = new DefaultListModel<String>();
        for (var file : fileEditorManager.getOpenFiles()) listModel.addElement(file.getName());
        SwingUtilities.invokeLater(() -> this.openFiles.setModel(listModel));
    }

    public JPanel getRootElement() {
        return root;
    }

    @Override
    public void dispose() {
        if (messageBusConnection != null) messageBusConnection.disconnect();
    }
}
