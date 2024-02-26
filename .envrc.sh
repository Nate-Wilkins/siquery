#!/bin/bash

function develop() {
  nix develop --experimental-features 'nix-command flakes' --ignore-environment  .
}

function build() {
  nix build   --experimental-features 'nix-command flakes' --show-trace --verbose --option eval-cache false .
}
