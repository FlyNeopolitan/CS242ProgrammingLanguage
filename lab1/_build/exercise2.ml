open Core

exception Unimplemented

module type IntTree = sig
  type tree = Leaf | Node of tree * int * tree
  val size : tree -> int
  val map : (int -> int) -> tree -> tree
  val to_string : tree -> string
  val binary_search : tree -> int -> int option
end

module IntTreeImpl : IntTree = struct
  type tree = Leaf | Node of tree * int * tree

  let rec size (t : tree) : int =
    match t with
    | Leaf -> 0
    | Node (l, _, r) -> 1 + (size l) + (size r)

  let rec map (f : int -> int) (t : tree) =
    match t with 
    | Leaf -> Leaf
    | Node (l, n, r) -> Node (map f l, f n, map f r)

  let rec to_string (t : tree) : string =
    match t with 
    | Leaf -> "()"
    | Node (l, n, r) -> Printf.sprintf "(%s, %d, %s)" (to_string l) n (to_string r)

  let rec binary_search (t : tree) (n : int) : int option =
    match t with 
    | Leaf -> None
    | Node (l, x, r) -> 
        if x = n then Some x 
        else if  x > n then binary_search l n
        else let right = binary_search r n 
          in if right = None then Some x else right
end

module IntTreeTests(T : IntTree) = struct
  let t : T.tree = T.Node(T.Leaf, 2, T.Leaf) in
  assert (T.size t = 1);
  assert (T.to_string t = "((), 2, ())");
  assert (T.map (fun x -> x + 1) t = T.Node(T.Leaf, 3, T.Leaf));

  let t = T.Node(T.Node(T.Leaf, 1, T.Leaf), 3 ,T.Node(T.Leaf, 5, T.Leaf)) in
  assert (T.binary_search t 2 = Some 1);
  assert (T.binary_search t 3 = Some 3);
  assert (T.binary_search t 6 = Some 5);
  assert (T.binary_search t 0 = None)
end

module Tests = IntTreeTests(IntTreeImpl)
