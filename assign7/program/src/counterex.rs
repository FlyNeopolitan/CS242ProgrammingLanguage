use session_bug::*;

fn sample_bug() {
  // this is only a bug **if** you comment out the Chan<Close> implementation
  // on line 63. you should get a compile error
  type Server = Close;
  let (c, _): (Chan<Server>, _) = Chan::new();
  c.close();
}

// on line 26, 'type Dual = Recv<T, S::Dual>;' should be corrected as ‘type Dual = Send<T, S::Dual>;’
pub fn bug1() {
  type Server = Recv<i32, Close>;
  type Client = <Server as HasDual>::Dual;
  let (c1, c2): (Chan<Server>, Chan<Client>) = Chan::new();
  c2.send(0)
}

// on line 71, 'pub fn send(self, x: T) -> Chan<Send<T, S>> {' should be corrected as 
// 'pub fn send(self, x: T) -> Chan<S> {'
pub fn bug2() {
  type Server = Send<i32, Close>;
  type Client = <Server as HasDual>::Dual;
  let (c1, c2): (Chan<Server>, Chan<Client>) = Chan::new();
  let c1 = c1.send(0);
  c1.close();
}

// on line 115, 'if self.read() {' should be corrected as 'if not self.read() {' 
// since left sent false and right sent true
pub fn bug3() {
  type Server = Choose<Recv<u64, Close>, Close>;
  type Client = <Server as HasDual>::Dual;
  let (c1, c2): (Chan<Server>, Chan<Client>) = Chan::new();
  let c1 = c1.left();
  let Branch::Left(c2) = c2.offer();
  c2.send(0);
}

#[cfg(test)]
mod tests {
  #[test]
  fn bug1() {
    super::bug1();
  }

  #[test]
  fn bug2() {
    super::bug2();
  }

  #[test]
  fn bug3() {
    super::bug3();
  }
}
