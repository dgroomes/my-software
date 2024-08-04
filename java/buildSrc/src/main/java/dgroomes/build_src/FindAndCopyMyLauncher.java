package dgroomes.build_src;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.OutputDirectory;
import org.gradle.api.tasks.TaskAction;

import java.io.File;

/**
 * Find the 'my-launcher' executable from the local system and copy it to the build directory. The local system is
 * expected to have the 'my-launcher' executable on the PATH.
 */
public class FindAndCopyMyLauncher extends DefaultTask {

    @TaskAction
    public void findAndCopyMyLauncher() {
        for (String path : System.getenv("PATH").split(File.pathSeparator)) {
            var myLauncher = new File(path, "my-launcher");
            if (myLauncher.exists()) {
                getProject().copy(spec -> {
                    spec.from(myLauncher);
                    // This is a little too long in the tooth for me. "my-launcher/launcher/my-launcher" is redundant.
                    spec.into(getOutputDir());
                });
                return;
            }
        }

        throw new RuntimeException("Could not find the 'my-launcher' executable on the PATH");
    }

    @Override
    public String getDescription() {
        return "Find the 'my-launcher' executable from the local system and copy it to the build directory";
    }

    @OutputDirectory
    public File getOutputDir() {
        var myLauncherDir = new File(getProject().getLayout().getBuildDirectory().getAsFile().get(), "my-launcher");
        return new File(myLauncherDir, "launcher");
    }
}
