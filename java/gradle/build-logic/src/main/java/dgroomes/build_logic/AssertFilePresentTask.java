package dgroomes.build_logic;

import org.gradle.api.DefaultTask;
import org.gradle.api.GradleException;
import org.gradle.api.file.RegularFileProperty;
import org.gradle.api.tasks.InputFile;
import org.gradle.api.tasks.PathSensitive;
import org.gradle.api.tasks.PathSensitivity;
import org.gradle.api.tasks.TaskAction;

public abstract class AssertFilePresentTask extends DefaultTask {

    @InputFile
    @PathSensitive(PathSensitivity.NONE)
    public abstract RegularFileProperty getInputFile();

    @TaskAction
    public void assertPresent() {
        var file = getInputFile().get().getAsFile();
        if (!file.exists()) {
            throw new GradleException(
                    "The nu-lex sidecar binary is missing: " + file + "\n\n" +
                    "See rust/nu-lex/README.md for details."
            );
        }
    }
}
