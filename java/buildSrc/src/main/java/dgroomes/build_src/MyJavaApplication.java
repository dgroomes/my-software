package dgroomes.build_src;

import org.gradle.api.provider.Property;

/**
 * Similar in spirit to {@link org.gradle.api.plugins.JavaApplication} but adapted for {@link MyApplicationPlugin} and
 * with almost all the properties removed.
 */
public interface MyJavaApplication {

    /**
     * The fully qualified name of the application's main class.
     */
    Property<String> getMainClass();
}
