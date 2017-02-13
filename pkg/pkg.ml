#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"

open Topkg

let () =
    Pkg.describe "ezsqlite" @@ fun c ->
        Ok [
            Pkg.clib "lib/libezsqlite_stubs.clib";
            Pkg.mllib ~api:["Ezsqlite"] "lib/ezsqlite.mllib";
            Pkg.test ~dir:"test" "test/ezsqlite_test";
        ]
