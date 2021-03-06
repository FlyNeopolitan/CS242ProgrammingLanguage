open Core
open Result.Monad_infix
open Ast

exception Unimplemented

(* You need to implement the statics for the three remaining cases below,
 * Var, Lam, and App. We have provided you with an implementation for Int
 * and Binop that you may refer to.*)
let rec typecheck_term (env : Type.t String.Map.t) (e : Expr.t) : (Type.t, string) Result.t =
  match e with
  | Expr.Int _ -> Ok Type.Int
  | Expr.Binop (_, e1, e2) ->
    typecheck_term env e1
    >>= fun tau1 ->
    typecheck_term env e2
    >>= fun tau2 ->
    (match (tau1, tau2) with
     | (Type.Int, Type.Int) -> Ok Type.Int
     | _ -> Error ("One of the binop operands is not an int"))
  | Expr.Var x -> 
    (match String.Map.find env x with 
     | Some tau -> Ok tau 
     | None -> Error ("variable x doesn't have a type "))
  | Expr.Lam(x, arg_tau, e') -> 
    let nenv = String.Map.set ~key: x ~data: arg_tau env in
    typecheck_term nenv e'
    >>= fun tau ->
    Ok(Type.Fn(arg_tau, tau))
  | Expr.App (fn, arg) -> 
    typecheck_term env fn
    >>= fun tau1 ->
    typecheck_term env arg
    >>= fun tau2 ->
    (match (tau1, tau2) with 
     | (Type.Fn(t1, t2), t3) when t3 = t1 -> Ok t2
     | _ -> Error ("The argument for function has wrong type"))

  | Expr.Pair (e1, e2) -> 
    typecheck_term env e1 
    >>= fun tau1 ->
    typecheck_term env e2
    >>= fun tau2 ->
    Ok(Type.Product(tau1, tau2))
  | Expr.Project (e, d) -> 
    typecheck_term env e 
    >>= fun tau ->
    (match tau with 
     | Type.Product(tau1, tau2) -> 
       (match d with 
        | Expr.Left -> Ok(tau1) 
        | Expr.Right -> Ok(tau2))
     | _ -> Error ("Projection of non pair"))
  | Expr.Inject (e, d, tau) -> 
    (match tau with
     | Type.Sum(tau1, tau2) -> 
         (match d with 
         | Expr.Left -> typecheck_term env e 
                     >>= fun tau -> 
                     if tau = tau1 then Ok(Type.Sum(tau1, tau2)) else Error("Injection over wrong type")
         | Expr.Right -> typecheck_term env e 
                     >>= fun tau ->
                     if tau = tau2 then Ok(Type.Sum(tau1, tau2)) else Error("Injection over wrong type"))
     | _ -> Error("Injection over non sum"))
    
  | Expr.Case (e, (x1, e1), (x2, e2)) -> 
    typecheck_term env e 
    >>= fun tau -> 
    (match tau with 
      | Type.Sum(tau1, tau2) -> 
          let nenv = String.Map.set ~key: x1 ~data: tau1 env
          in typecheck_term nenv e1 
          >>= fun tau3 ->
          let nenv = String.Map.set ~key: x2 ~data: tau2 env
          in typecheck_term nenv e2
          >>= fun tau4 -> if tau3 = tau4 then Ok(tau3) else Error("Case1 and Case2 doesn't provide same type")
      | _ -> Error("e is not sum type in Case"))
     

let typecheck t = typecheck_term String.Map.empty t

let inline_tests () =
  let e1 = Expr.Lam ("x", Type.Int, Expr.Var "x") in
  assert (typecheck e1 = Ok(Type.Fn(Type.Int, Type.Int)));

  let e2 = Expr.Lam ("x", Type.Int, Expr.Var "y") in
  assert (Result.is_error (typecheck e2));

  let t3 = Expr.App (e1, Expr.Int 3) in
  assert (typecheck t3 = Ok(Type.Int));

  let t4 = Expr.App (t3, Expr.Int 3) in
  assert (Result.is_error (typecheck t4));

  let t5 = Expr.Binop (Expr.Add, Expr.Int 0, e1) in
  assert (Result.is_error (typecheck t5));

  let t6 = Expr.Pair(Expr.Int 2, Expr.Int 3) in 
  assert (typecheck t6 = Ok(Type.Product(Type.Int, Type.Int)))

(* Uncomment the line below when you want to run the inline tests. *)
let () = inline_tests () 
