#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"

open Topkg

let () =
    Pkg.describe "ezsqlite" @@ fun c ->
        Ok [
            Pkg.mllib "lib/ezsqlite.mllib";
            Pkg.clib "lib/libezsqlite_stubs.clib";
        ]
