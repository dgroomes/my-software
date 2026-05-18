# SDR: Dictation

The decision is that I intend to support using dictation more in my own programming workflows.


## Overview

I use speech-to-text (STT) to great effect when writing prompts. I literally just click the microphone button in ChatGPT. It works great, except for the occasional times that it fails and I lose the whole recording. That's a bummer. It's also not good at some jargon, like "Nushell", which it usually interprets as "new shell". Overall though, I can't complain.

But, STT is very accessible and I can get something better. I could go the full local route, but for now I'll just use paid APIs like OpenAI's transcribe or even the realtime ones.

Building any tooling around this will only be worth it if I can get better accuracy, rather a reduced word error rate (WER). This should be easy because the APIs usually support some prompt text where you can give some guidance like "Nushell" (I don't have a feel for what kind of content you can put here actually). I also aspire to use thinking models, where ostensibly I could pack much more rules, a spoken glossary of words with their text counterparts, and the model should be able to use that info to produce a more accurate response. These models, like `gpt-realtime-2`, are not fine-tuned for transcription so they should be much more steerable. This is just my guess though, I see very little prior art for this so maybe I should just stick with the common paths for transcription.

I've also settled on "dictation" as the keyword because the way I'm using this is that my speaking is just the vehicle to get the written word. I don't need to capture every literal utterance, which would be a transcription use-case.

The cheap prototype is ffmpeg, OpenAI's `gpt-4o-transcribe` model via the API, and some Nushell scripting.

If I want to get fancier with the implementation, I must also use evals so that I can actually demonstrate that it's worth it.
