open Ocamlbuild_plugin

let () = dispatch begin function
    | After_rules ->
      (*dep ["c"; "compile"; "use_ezsqlite_headers"] ["src/ocaml_ezsqlite.h"];*)

      flag ["use_ezsqlite_stubs"] &
        S[A"-I"; A"lib"];

      dep ["ocaml"; "link"; "byte"; "library"; "use_ezsqlite_stubs"]
        ["lib/dllezsqlite"-.-(!Options.ext_dll)];
      flag ["ocaml"; "link"; "byte"; "library"; "use_ezsqlite_stubs"] &
        S[A"-dllib"; A"-lezsqlite_stubs"];

      dep ["ocaml"; "link"; "native"; "library"; "use_ezsqlite_stubs"]
        ["lib/libezsqlite"-.-(!Options.ext_lib)];
      flag ["ocaml"; "link"; "native"; "library"; "use_ezsqlite_stubs"] &
        S[A"-cclib"; A"-lezsqlite_stubs"];
    | _ -> ()
end
