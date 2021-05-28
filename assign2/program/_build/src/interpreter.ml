open Core
open Ast

type outcome =
  | Step of Expr.t
  | Val

exception RuntimeError of string
exception Unimplemented

(* You will implement the App, Binop, Pair, Project, Inject, and Case cases
   below. See the dynamics section for a specification on how the small step
   semantics should work. *)
let rec trystep e =
  match e with
  | Expr.Var _ -> raise (RuntimeError "Unreachable")
  | (Expr.Lam _ | Expr.Int _) -> Val
  | Expr.App (fn, arg) -> 
    (match trystep fn with
    | Step gn -> Step (Expr.App(gn, arg))
    | Val -> (match fn with 
             | Expr.Lam(x, _, body) -> Step(Expr.substitute x arg body)
             | _ -> raise (RuntimeError "not a function")))
  | Expr.Binop (binop, left, right) -> 
    (match trystep left with
    | Step newL -> Step (Expr.Binop(binop, newL, right))
    | Val -> (match trystep right with
             | Step newR -> Step (Expr.Binop(binop, left, newR))
             | Val -> let (Expr.Int n1, Expr.Int n2) = (left, right) in 
                      (match binop with 
                      | Expr.Add -> Step(Expr.Int(n1 + n2))
                      | Expr.Sub -> Step(Expr.Int(n1 - n2))
                      | Expr.Mul -> Step(Expr.Int(n1 * n2))
                      | Expr.Div -> Step(Expr.Int(if n2 = 0 then 0 else n1 / n2)))))
  | Expr.Pair (e1, e2) -> 
    (match trystep e1 with 
    | Step e1' -> Step(Expr.Pair(e1', e2))
    | Val -> (match trystep e2 with
              | Step e2' -> Step(Expr.Pair(e1, e2'))
              | Val -> Val))
  | Expr.Project (e, dir) -> 
    (match trystep e with 
    | Step e' -> Step(Expr.Project(e', dir))
    | Val -> let Expr.Pair(e1, e2) = e 
             in (match dir with 
                 | Expr.Left -> Step(e1) 
                 | Expr.Right -> Step(e2)))
  | Expr.Inject (e, dir, tau) -> 
     (match trystep e with 
      | Step e' -> Step(Expr.Inject(e', dir, tau))
      | Val -> Val)
  | Expr.Case (e, (x1, e1), (x2, e2)) -> 
      (match trystep e with 
      | Step e' -> Step(Expr.Case(e', (x1, e1), (x2, e2)))
      | Val -> let Expr.Inject(e', dir, _) = e 
               in (match dir with 
                  | Expr.Left -> Step(Expr.substitute x1 e' e1)
                  | Expr.Right -> Step(Expr.substitute x2 e' e2)))

let rec eval e =
  match trystep e with
  | Step e' -> eval e'
  | Val -> Ok e

let inline_tests () =
  let e1 = Expr.Binop(Expr.Add, Expr.Int 2, Expr.Int 3) in
  assert (trystep e1 = Step(Expr.Int 5));

  let e2 = Expr.App(Expr.Lam("x", Type.Int, Expr.Var "x"), Expr.Int 3) in
  assert (trystep e2 = Step(Expr.Int 3))

(* Uncomment the line below when you want to run the inline tests. *)
 let () = inline_tests ()
