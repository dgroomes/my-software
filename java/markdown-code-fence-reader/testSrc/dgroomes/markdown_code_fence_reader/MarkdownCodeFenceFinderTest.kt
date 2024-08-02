package dgroomes.markdown_code_fence_reader

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class MarkdownCodeFenceFinderTest {

    @Test
    fun simple() {
        val markdownContent = """
                ```shell
                echo 'Hello, world!'
                ```
                """.trimIndent()

        val snippets = findSnippets(markdownContent)

        assertThat(snippets).hasSize(1)
        assertThat(snippets.first()).isEqualTo(ShellSnippet("shell", "echo 'Hello, world!'"))
    }

    @Test
    fun bashSnippet() {
        val markdownContent = """
                ```bash
                echo {1..5}
                ```
                """.trimIndent()

        val snippets = findSnippets(markdownContent)

        assertThat(snippets).hasSize(1)
    }

    @Test
    fun codeFencesInsideOtherElements() {
        val markdownContent = """
                > ```shell
                > echo hello
                > ```
                """.trimIndent()

        val snippets = findSnippets(markdownContent)

        assertThat(snippets).hasSize(1)
    }

    @Test
    fun multiLineSnippet() {
        val markdownContent = """
                ```shell
                if which nu > /dev/null; then
                  echo "nushell is installed"
                else
                  echo "nushell is not installed"
                fi
                ```
                """.trimIndent()

        val snippets = findSnippets(markdownContent)

        assertThat(snippets).hasSize(1)
        assertThat(snippets.first()).isEqualTo(
            ShellSnippet(
                "shell", """
                if which nu > /dev/null; then
                  echo "nushell is installed"
                else
                  echo "nushell is not installed"
                fi
                """.trimIndent()
            )
        )
    }
}
