# proto

Protobuf definition files for various subsystems in the project. I'm not sure that I'm going to use this long-term. Just
experimenting.

I'm using [Buf](https://github.com/bufbuild/buf) because it has a really nice story for working with Protobuf
throughout the development lifecycle (authoring `.proto` files, downloading/managing `protoc` plugins, codegen, etc.).


## Miscellaneous

```nushell
{ error_message: "Something went wrong" } | to json | buf convert java_body_omitter.proto --type Error --from -#format=json
```

```nushell
{ error: { error_message: "Something went wrong" } } | to json | buf convert java_body_omitter.proto --type Response --from -#format=json
```

Here is an illegal message. It specifies both an `error` and a `success` field. It will fail with "Failure: --from: proto: (line 5:3): error parsing "success", oneof Response.response is already set".
```nushell
{ error: { error_message: "Something went wrong" } success: { java_code: "class Foo ..." } } | to json | buf convert java_body_omitter.proto --type Response --from -#format=json
```
