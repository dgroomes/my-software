package dgroomes;

import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.fileEditor.FileEditorManager;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.openapi.ide.CopyPasteManager;
import java.awt.datatransfer.StringSelection;

public class CopyOpenTabsAction extends AnAction {

    @Override
    public void actionPerformed(AnActionEvent e) {
        Project project = e.getProject();
        if (project == null) return;

        FileEditorManager fileEditorManager = FileEditorManager.getInstance(project);
        VirtualFile[] openFiles = fileEditorManager.getOpenFiles();

        StringBuilder fileNames = new StringBuilder();
        for (VirtualFile file : openFiles) {
            fileNames.append(file.getName()).append("\n");
        }

        // Copy to clipboard
        CopyPasteManager.getInstance().setContents(new StringSelection(fileNames.toString()));
    }
}
