import sys

import tiktoken


def token_count():
    """
    Estimate the number of tokens in the text supplied via standard input.

    I say "estimate" because different models use different tokenizers, and we don't have access to all of them. For
    OpenAI models, we do have access via the 'tiktoken' package. For Anthropic models, we don't. I don't need a precise
    token count, I just want to know the ballpark. I'm going to hardcode "o200k_base" because that's what GPT-4o uses,
    """
    content = sys.stdin.read()
    encoding = tiktoken.get_encoding("o200k_base")
    print(len(encoding.encode(content)))


if __name__ == "__main__":
    token_count()
