package dgroomes.build_src;

import com.fasterxml.jackson.core.util.DefaultIndenter;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.gradle.api.DefaultTask;
import org.gradle.api.GradleException;
import org.gradle.api.file.FileCollection;
import org.gradle.api.model.ObjectFactory;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.*;
import org.gradle.work.DisableCachingByDefault;

import javax.inject.Inject;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * Create a 'my-java-launcher.json' manifest file.
 */
@DisableCachingByDefault(because = "Not worth caching")
public class CreateMyLauncherManifest extends DefaultTask {

    private final Property<String> mainClass;
    private final Property<FileCollection> classpath;

    @Inject
    public CreateMyLauncherManifest(ObjectFactory objectFactory) {
        this.mainClass = objectFactory.property(String.class);
        this.classpath = objectFactory.property(FileCollection.class);
    }

    @Input
    public Property<String> getMainClass() {
        return mainClass;
    }

    @Classpath
    public Property<FileCollection> getClasspath() {
        return classpath;
    }

    @TaskAction
    public void createManifest() {
        var mapper = new ObjectMapper();

        ObjectNode manifest;
        {
            manifest = mapper.createObjectNode()
                    .put("program_type", "java")
                    .put("entrypoint", mainClass.get());

            var javaConfig = manifest.putObject("java_configuration")
                    .put("java_version", 21);

            var classpathArray = javaConfig.putArray("classpath");
            for (var file : getClasspath().get()) classpathArray.add("../lib/" + file.getName());
        }

        ObjectWriter jsonWriter;
        {
            var prettyPrinter = new DefaultPrettyPrinter();
            prettyPrinter.indentArraysWith(new DefaultIndenter());
            jsonWriter = mapper.writer(prettyPrinter);
        }

        try (var fileWriter = new FileWriter(getManifest())) {
            jsonWriter.writeValue(fileWriter, manifest);
        } catch (IOException e) {
            throw new GradleException("Something went wrong while writing the 'my-java-launcher.json' manifest file", e);
        }
    }

    @Override
    public String getDescription() {
        return "Creates a 'my-java-launcher' manifest file and copies in the 'my-java-launcher' executable.";
    }

    @OutputDirectory
    public File getOutputDir() {
        var myLauncherDir = new File(getProject().getLayout().getBuildDirectory().getAsFile().get(), "my-java-launcher");
        return new File(myLauncherDir, "manifest");
    }

    @Internal
    public File getManifest() {
        return new File(getOutputDir(), "my-java-launcher.json");
    }
}
