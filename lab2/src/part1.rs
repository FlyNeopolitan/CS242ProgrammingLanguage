use std::{ptr, io};

fn password_checker(s: String) {
  let mut guesses = 0;
  loop {
    let mut buffer = String::new();
    if let Err(_) = io::stdin().read_line(&mut buffer) { return; }
    if buffer.len() == 0 { return; }

    // If the buffer is "Password1" then print "You guessed it!" and return,
    // otherwise print the number of guesses so far.
   if buffer == "Password1" {
     println!("You guessed it!");
     return
   } else {
    println!("{}", guesses);
    guesses = guesses + 1
   }
  }
}

fn add_n(v: Vec<i32>, n: i32) -> Vec<i32> {
  let mut res: Vec<i32> = Vec::new();
  for i in v.iter() {
    res.push(*i + n);
  }
  return res
}

fn add_n_inplace(v: &mut Vec<i32>, n: i32) {
  for i in v.iter_mut() {
    *i = *i + n
  }
}

fn reverse_clone<T: Clone>(v: &mut Vec<T>) {
    let n = v.len();
    for i in 0..n/2 {
        let x: T = v[i].clone();
        v[i] = v[n-i-1].clone();
        v[n-i-1] = x;
    }
}

fn reverse<T>(v: &mut Vec<T>) {
  let n = v.len();
  for i in 0..n/2 {
    v.swap(i, n - i - 1)
  }
}

#[cfg(test)]
mod test {
  use super::*;

  #[test]
  fn test_password_checker() {
    //password_checker(String::from("Password1"));
  }

  #[test]
  fn test_add_n() {
    assert_eq!(add_n(vec![1], 2).pop().unwrap(), 3);
  }

  #[test]
  fn test_add_n_inplace() {
    let mut v = vec![1];
    add_n_inplace(&mut v, 2);
    assert_eq!(v[0], 3);
  }

  #[test]
  fn test_reverse() {
    let mut v = vec![1, 2, 3];
    reverse(&mut v);
    assert_eq!(v[0], 3);
  }
}
