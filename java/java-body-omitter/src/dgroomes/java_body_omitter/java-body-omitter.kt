package dgroomes.java_body_omitter

import java.io.IOException
import java.net.StandardProtocolFamily
import java.net.UnixDomainSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.ServerSocketChannel
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths


/**
 * Please see the README for more information.
 */
fun main(args: Array<String>) {
    println("Information. Java version: ${System.getProperty("java.version")}")

    if (args.isNotEmpty() && args[0] == "--daemon") {
        runDaemon()
    } else {
        val code = System.`in`.bufferedReader().use { it.readText() }
        val stripped = JavaBodyOmitter().strip(code)
        println(stripped)
    }
}

fun runDaemon() {
    val socketPath = "/tmp/java-body-omitter.socket"
    val address = UnixDomainSocketAddress.of(socketPath)

    println("Cleaning up pre-existing file...")
    Files.deleteIfExists(Paths.get(socketPath))

    println("Starting listener...")
    ServerSocketChannel.open(StandardProtocolFamily.UNIX).use { serverChannel ->
        serverChannel.bind(address)
        println("Daemon is listening on $socketPath")
        while (true) {
            try {
                serverChannel.accept().use { socketChannel ->
                    val buffer = ByteBuffer.allocate(8192)
                    val inputBuilder = StringBuilder()

                    // Read data from the client
                    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE") var bytesRead: Int
                    while ((socketChannel.read(buffer).also { bytesRead = it }) > 0) {
                        buffer.flip() // No idea what this is
                        inputBuilder.append(StandardCharsets.UTF_8.decode(buffer))
                        buffer.clear()
                    }

                    val input = inputBuilder.toString()

                    // Process the input using your existing code
                    val output = JavaBodyOmitter().strip(input)

                    // Write the output back to the client
                    val outputBuffer: ByteBuffer = StandardCharsets.UTF_8.encode(output)
                    socketChannel.write(outputBuffer)
                }
            } catch (e: IOException) {
                e.printStackTrace()
            }
        }
    }
}
