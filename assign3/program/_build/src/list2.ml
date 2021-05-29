open Core

exception Unimplemented

module type List2 = sig
  type 'a list = Cons of 'a * 'a list | Nil

  val foldr : ('a -> 'b -> 'b) -> 'b -> 'a list -> 'b
  val map : ('a -> 'b) -> 'a list -> 'b list
  val filter : ('a -> bool) -> 'a list -> 'a list
  val reduce : ('a -> 'a -> 'a) -> 'a list -> 'a option
  val combine_keys : ('a * 'b) list -> ('a * ('b list)) list
  val to_string : ('a -> string) -> 'a list -> string
end

module MyList : List2 = struct
  type 'a list = Cons of 'a * 'a list | Nil

  let rec foldr f base l =
    (match l with
     | Nil -> base
     | Cons(x, xs) -> f x (foldr f base xs))

  let to_string f l =
    foldr (fun x -> fun xs -> (f x) ^ " " ^ xs) "" l

  let map f l =
    foldr (fun a -> fun b -> Cons(f a, b)) Nil l

  let rec filter f l =
    (match l with 
     | Nil -> Nil
     | Cons(x, xs) -> 
       let tail = filter f xs
       in if f x then Cons(x, tail) else tail)

  let reduce f l =
    (match l with 
     | Nil -> None
     | _ -> 
       let helper x xs = 
         (match xs with
          | Nil -> Cons(x, Nil)
          | Cons(a, Nil) -> Cons(f x a, Nil))
       in let Cons(res, Nil) = foldr helper Nil l
       in Some(res))


  let combine_keys l =
    let helper x xs = 
      let (k, v) = x in 
      let search k y = 
        foldr (fun x-> fun c-> 
            let (head, _) = x in if head = k then true else c) false y
      in if not(search k xs) then Cons((k, Cons(v, Nil)), xs)
      else let merge a b = 
             let (h, keys) = a 
             in if h = k then Cons((k, Cons(v, keys)), b) else Cons(a, b)
        in foldr merge Nil xs
    in foldr helper Nil l
end

module ListTests(L : List2) = struct
  open L ;;

  let l = Cons(("b", 3), Cons(("a", 2), Cons(("a", 1), Nil))) in
  assert(
    (to_string (fun (s, n) -> Printf.sprintf "(%s, %s)" s (string_of_int n)) l)
    = "(b, 3) (a, 2) (a, 1) ");

  let l = combine_keys l in
  assert(
    l = Cons(("a", Cons(2, Cons(1, Nil))), Cons(("b", Cons(3, Nil)), Nil))
    || 
    l = Cons(("b", Cons(3, Nil)),  Cons(("a", Cons(2, Cons(1, Nil))), Nil))
  );

  let m = map (fun x -> x+1) (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = Cons(2, Cons(3, Cons(4, Cons(5, Cons(6, Nil))))));

  let m = map (fun x -> x*2) (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = Cons(2, Cons(4, Cons(6, Cons(8, Cons(10, Nil))))));

  let m = foldr (max) 0 (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = 5);

  let m = foldr (+) 0 (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = 15);

  let m = reduce (+) (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = Some 15);

  let m = reduce (max) (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = Some 5);

  let m = filter (fun x -> (x mod 2) = 0) (Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))) in
  assert (m = Cons(2, Cons(4, Nil)));

  let m = filter (fun x -> (x < 0)) (Cons(-1, Cons(2, Cons(100, Cons(0, Cons(-5, Nil)))))) in
  assert (m = Cons(-1, Cons(-5, Nil)));

end

module MyListTests = ListTests(MyList)