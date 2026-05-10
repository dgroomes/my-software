package dgroomes.build_logic;

import org.gradle.api.model.ObjectFactory;
import org.gradle.api.provider.Property;

public class DefaultMyJavaApplication implements MyJavaApplication {

    private final Property<String> mainClass;

    public DefaultMyJavaApplication(ObjectFactory objectFactory) {
        this.mainClass = objectFactory.property(String.class);
    }

    @Override
    public Property<String> getMainClass() {
        return mainClass;
    }
}
