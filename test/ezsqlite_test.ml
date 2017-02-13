
let test_db t =
    let db = Ezsqlite.load "_test.db" in
    let _ = Test.check t "Database created" (fun () ->
        Sys.file_exists "_test.db") true
    in db

let test_stmt t db =
    let _ = Test.check_raise t "Invalid SQL" (fun () ->
        let _ = Ezsqlite.prepare db "testing" in ()) in
    let stmt = Ezsqlite.prepare db "CREATE TABLE testing (id INTEGER PRIMARY KEY, a TEXT, b BLOB, c INT, d DOUBLE);" in
    let _ = Test.check t "Create Table Step" (fun () ->
        Ezsqlite.exec stmt) ()
    in ()


let _ =
    let t = Test.start () in
    let _ = try Sys.remove "_test.db" with _ -> () in
    let db = test_db t in
    let _ = test_stmt t db in
    Test.finish t

