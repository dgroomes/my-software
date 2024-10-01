package dgroomes.java_body_omitter

import dgroomes.java_body_omitter.proto.Error
import dgroomes.java_body_omitter.proto.Response
import dgroomes.java_body_omitter.proto.Success
import java.net.StandardProtocolFamily
import java.net.UnixDomainSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.ServerSocketChannel
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths
import java.util.concurrent.Executors

/**
 * Please see the README for more information.
 */
fun main(args: Array<String>) {
    val isDaemon = args.contains("--daemon")
    val isProtobuf = args.contains("--protobuf")

    val emitter = if (isProtobuf) protobufEmitter else stringEmitter
    val runner = if (isDaemon) daemonRunner(emitter) else oneShotRunner(emitter)

    runner.run()
}

fun interface Emitter {
    fun emit(result: StripResult): ByteArray
}

val protobufEmitter = Emitter {
    when (it) {
        is StripResult.Success -> {
            val success = Success.newBuilder().setJavaCode(it.strippedCode)
            val response = Response.newBuilder().setSuccess(success.build()).build()
            response.toByteArray()
        }

        is StripResult.Error -> {
            val err = Error.newBuilder().setErrorMessage(it.errorMessage).build()
            val response = Response.newBuilder().setError(err).build()
            response.toByteArray()
        }
    }
}

val stringEmitter = Emitter { result ->
    when (result) {
        is StripResult.Success -> {
            result.strippedCode.toByteArray()
        }

        is StripResult.Error -> {
            result.errorMessage.toByteArray()
        }
    }
}

fun interface Runner {
    fun run()
}

fun daemonRunner(emitter: Emitter) = Runner {
    val javaBodyOmitter = JavaBodyOmitter()

    val socketPath = "/tmp/java-body-omitter.socket"
    val address = UnixDomainSocketAddress.of(socketPath)

    println("Cleaning up pre-existing file...")
    Files.deleteIfExists(Paths.get(socketPath))

    val executor = Executors.newVirtualThreadPerTaskExecutor()
    Runtime.getRuntime().addShutdownHook(Thread {
        println("Shutting down executor...")
        executor.shutdown()
    })

    println("Starting listener...")
    // Note: consider handling errors. Consider implementing graceful shutdown.
    ServerSocketChannel.open(StandardProtocolFamily.UNIX).use { serverChannel ->
        serverChannel.bind(address)
        println("Daemon is listening on $socketPath")
        while (true) {
            val sockChan = serverChannel.accept()
            executor.submit {
                sockChan.use { socketChannel ->
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

                    val output = javaBodyOmitter.strip(input)
                    val toEmit: ByteArray = emitter.emit(output)

                    socketChannel.write(ByteBuffer.wrap(toEmit))
                }
            }
        }
    }
}

fun oneShotRunner(emitter: Emitter) = Runner {
    val code = System.`in`.bufferedReader().use { it.readText() }
    val stripResult = JavaBodyOmitter().strip(code)
    val response = emitter.emit(stripResult)
    System.out.write(response)
}
