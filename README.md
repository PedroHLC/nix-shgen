# nix-shgen
Generate multi-platform multi-project shell scripts

## Reason

Why do this? No reason at all. Just a POC to satisfy my curious mind.

## Contributing

If you want to add extra stuff, feel free to.

If you find an use-case to this, let me know!

## How to

There is an `example.json`, you can try make a dash-compatible script to it with:

```sh
nix build .#exampleDash
```

If you want to see it how Nix sees it, maybe transpile it:

```sh
nix build .#exampleJson
jq . ./result
```
