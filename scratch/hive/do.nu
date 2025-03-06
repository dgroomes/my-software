const DIR = path self | path dirname

# Build Apache Hive from source.
#
# See https://hive.apache.org/docs/latest/building-hive-from-source_282102252/
export def build-hive [] {
    cd ~/repos/opensource/hive
    git checkout rel/release-4.0.1

    activate-my-open-jdk 8

    # I'm conditionally omitting the "clean" in hopes I don't have to always be waiting.
    mvn install -DskipTests -Pdist -Piceberg -Pitests
}
