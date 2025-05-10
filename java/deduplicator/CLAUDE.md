# Claude Instructions for the 'deduplicator' Subproject


## Values, Principles, and Vision

The vision of the 'deduplicator' subproject is that it is an algorithmically efficient implementation for text
deduplication. This efficiency comes at the cost of algorithmic complexity. We need to offset this cost by being concise
in the implementation, and clear in the story and progression told by the tests and examples. The Suffix Array Induced Sorting
(SA-IS) algorithm is **constant time**. Never devolve into a slower algorithm. This is hard stuff so think harder, and
ultrathink.


## Test Commands

When verifying code changes, run these commands:

```bash
# Run all tests
../gradlew test

# Run a specific test class
../gradlew test --tests "my.dedupe.DeduplicatorTest"

# Run a specific test method
../gradlew test --tests "my.dedupe.DeduplicatorTest.should deduplicate simple repeated text"
```


## Project Structure

- `src/my/dedupe/Main.kt` - Command-line interface
- `src/my/dedupe/algorithm.kt` - Core algorithms like the SA-IS algorithm
- `src/my/dedupe/debug.kt` - Debugging utilities
- `testSrc/my/dedupe/DeduplicatorTest.kt` - Main test cases
- `testSrc/my/dedupe/ScratchTest.kt` - Experimental test cases


## Routines

1. *Retranscribe project structure*: I will occasionally ask to transcribe the 'Project Structure' section of this
   document based on the current state of the repository. Recreate it from scratch by reading all files in this subproject.
