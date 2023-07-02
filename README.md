# 8086-nix-sit-mmvm
A nix flake for a minix2 8086 emulator 
for advanced OS class at Shibaura Institute of Technology

## How to use

The project is a nix flake built around a C project.

### Installing the emulator

```bash
$ nix profile install github:m1dugh/8086-nix-sit-mmvm/#mmvm
```

### Installing all the packages to run minix2 environment

```bash
$ nix profile install github:m1dugh/8086-nix-sit-mmvm/#minix2
```

This packages provides a few binaries:
- mmvm: A minix2 binary decompiler and emulator
- m2cc: A minix2 C compiler
