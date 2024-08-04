package dgroomes.build_src;

import org.gradle.api.Plugin;
import org.gradle.api.Project;
import org.gradle.api.distribution.Distribution;
import org.gradle.api.distribution.DistributionContainer;
import org.gradle.api.distribution.plugins.DistributionPlugin;
import org.gradle.api.file.CopySpec;
import org.gradle.api.file.FileCollection;
import org.gradle.api.plugins.JavaPlugin;
import org.gradle.api.plugins.internal.JavaPluginHelper;
import org.gradle.api.plugins.jvm.internal.JvmFeatureInternal;
import org.gradle.api.tasks.TaskProvider;
import org.gradle.api.tasks.bundling.Jar;

/**
 * This Gradle {@link Plugin} is an alternative to the <a href="https://docs.gradle.org/current/userguide/application_plugin.html">Application plugin</a>.
 * This plugin serves the same purpose, but uses the 'my-launcher' executable and manifest file instead of a POSIX shell
 * script (called the "start script") for launching the Java program.
 * <p>
 * I have some design thoughts on this plugin:
 *
 * <ul>
 *     <li>Don't bother supporting a 'run' task. I can just run from Intellij.</li>
 *     <li>Don't bother supporting toolchains.</li>
 *     <li>Don't bother supporting JPMS.</li>
 *     <li>Don't bother supporting the zip/tar tasks.</li>
 *     <li>Don't bother supporting system properties and environment variables</li>
 *     <li>Do NOT re-use the {@link org.gradle.api.plugins.JavaApplication} class because it uses conventions which is a deprecated Gradle concept, and I dont' need all the fields.</li>
 * </ul>
 */
public class MyApplicationPlugin implements Plugin<Project> {

    @Override
    public void apply(final Project project) {
        project.getPluginManager().apply(JavaPlugin.class);
        project.getPluginManager().apply(DistributionPlugin.class);

        JvmFeatureInternal mainFeature = JavaPluginHelper.getJavaComponent(project).getMainFeature();

        MyJavaApplication extension = project.getExtensions().create(MyJavaApplication.class, "application", DefaultMyJavaApplication.class);

        var createMyLauncherManifest = project.getTasks().register("createMyLauncherManifest", CreateMyLauncherManifest.class, task -> {
            task.getMainClass().set(extension.getMainClass());
            task.getClasspath().set(jarsOnlyRuntimeClasspath(mainFeature));
        });

        var findAndCopyMyLauncher = project.getTasks().register("findAndCopyMyLauncher", FindAndCopyMyLauncher.class);

        CopySpec distSpec;
        {
            DistributionContainer distributions = project.getExtensions().getByType(DistributionContainer.class);
            Distribution mainDistribution = distributions.getByName(DistributionPlugin.MAIN_DISTRIBUTION_NAME);
            mainDistribution.getDistributionBaseName().convention(project.getName());
            distSpec = mainDistribution.getContents();
        }

        TaskProvider<Jar> jar = mainFeature.getJarTask();

        distSpec.into("lib", lib -> {
            lib.from(jar);
            lib.from(mainFeature.getRuntimeClasspathConfiguration());
        });

        distSpec.into("bin", bin -> {
            bin.from(findAndCopyMyLauncher).rename("my-launcher", project.getName());
        });

        distSpec.into("bin", bin -> {
            bin.from(createMyLauncherManifest);
        });
    }

    private FileCollection jarsOnlyRuntimeClasspath(JvmFeatureInternal mainFeature) {
        return mainFeature.getJarTask().get().getOutputs().getFiles().plus(mainFeature.getRuntimeClasspathConfiguration());
    }
}
