# Menu
This repository contains QOL scripts I've written for NixOS, specifically surrounding rebuilding and updating flake inputs.

## unify
`unify`, or "Update NixOS Inputs For Yourself", is a wrapper around `nix flake update`. Its main feature is its **Important Inputs** list -- you can specify which inputs you find important enough to trigger a `flake.lock` update commit. For example, you'd probably want to update your `flake.lock` for `nixpkgs`, but you might not care about making a whole update commmit just for `firefox-addons`. Unify attempts to automate this, so you can simply run it, and it'll only go through the motions if the updates are "worth it".

Several other features are provided, to serve the goal of `unify` automatically doing the common parts of the flake update process. These include:
- Automatically swapping branches to whatever branches you specify as your **primary branch**, so you don't accidentally commit `flake.lock` changes on a feature branch
- Ensuring that the system rebuilds without failure before committing
- Reverting any state created during execution. If the `flake.lock` changes didn't update any **important inputs**, it will revert the changes to the `flake.lock`. It will also automatically transfer you back onto your feature branch, if you were on one before starting execution

## fuiska
`fuiska`, or "Flake Updates I Should Know About?", serves to quickly tell you which flake inputs have been updated. `nix flake update` takes a long time to run, especially as your number of inputs grows. This is because it doesn't just check whether a given input *has* updated - it also actually fetches the new commit data. `fuiska` just checks whether the hash of the new commit differs, using only with `jq` and `git`. `fuiska` is also parallelized, massively speeding up execution. On my laptop with 15 flake inputs, `nix flake update` takes TODO seconds, while `fuiska` takes 0.5 seconds.

`fuiska` aims to provide a more purposeful alternative to the Unify workflow. Rather than simply providing a list of flake inputs that trigger a commit, `fuiska` instead just tells you the inputs that would be updated quickly, letting you decide whether to commit. I personally *prefer* this workflow, but this depends on the individual.

## rbld
`rbld`, or "Rebuild But Less Dumb", is a fairly simple `nixos-rebuild` wrapper. Its main features are adding any newly added files to the Git index via `git add -AN`, and piping output to [nix-output-monitor](https://github.com/maralorn/nix-output-monitor). There isn't much unique functionality here - you're free to use this, but you could also write your own script with very similar functionality.

## Installation 
To install any of these packages, TODO

## Environment variables
TODO