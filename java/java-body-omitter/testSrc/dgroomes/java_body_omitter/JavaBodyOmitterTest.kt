package dgroomes.java_body_omitter

import org.junit.jupiter.api.Test
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach

@Suppress("MemberVisibilityCanBePrivate")
class JavaBodyOmitterTest {

    lateinit var jbo: JavaBodyOmitter

    @BeforeEach
    fun setUp() {
        jbo = JavaBodyOmitter()
    }

    @Test
    fun `omit method body`() {
        val input = """
            class Foo {
                void hello() {
                    println("This should be omitted");
                }
            }
        """.trimIndent()

        val result = jbo.strip(input)

        assertThat(result).isEqualTo(
            """
                class Foo {
                    void hello() {
                    }
                }
            """.trimIndent()
        )
    }

    @Test
    fun `omit constructor body`() {
        val input = """
            class Foo {
                Foo() {
                    println("Constructor body to be omitted");
                }
            }
        """.trimIndent()

        val result = jbo.strip(input)

        assertThat(result).isEqualTo(
            """
                class Foo {
                    Foo() {
                    }
                }
            """.trimIndent()
        )
    }

    @Test
    fun `omit initializer block`() {
        val input = """
            class Foo {
                {
                    println("Initializer block to be omitted");
                }
            }
        """.trimIndent()

        val result = jbo.strip(input)

        assertThat(result).isEqualTo(
            """
                class Foo {
                    {
                    }
                }
            """.trimIndent()
        )
    }
}
