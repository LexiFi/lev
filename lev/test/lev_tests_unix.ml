open Printf
open Lev
module List = ListLabels

let%expect_test "child" =
  let loop = Loop.default () in
  let stdin, stdin_w = Unix.pipe ~cloexec:true () in
  let stdout_r, stdout = Unix.pipe ~cloexec:true () in
  let stderr_r, stderr = Unix.pipe ~cloexec:true () in
  Unix.close stdin_w;
  Unix.close stdout_r;
  Unix.close stderr_r;
  let pid =
    Unix.create_process "sh" [| "sh"; "-c"; "exit 42" |] stdin stdout stderr
  in
  let child =
    match Child.create with
    | Error `Unimplemented -> assert false
    | Ok create ->
        create
          (fun t ~pid:pid' status ->
            Child.stop t loop;
            (match status with
            | Unix.WEXITED i -> printf "exited with status %d\n" i
            | _ -> assert false);
            assert (pid = pid'))
          (Pid pid) Terminate
  in
  Child.start child loop;
  Loop.run_until_done loop;
  [%expect {| exited with status 42 |}]
