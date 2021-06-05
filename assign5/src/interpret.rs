extern crate memory;

use ast::*;

#[allow(unused_macros)]
macro_rules! fmt_state {
  ($x:ident) => (
    format!("{}: {:?}", stringify!($x), $x)
  );
  ($x:ident, $($y:ident),*) => (
    format!("{} | {}", fmt_state!($x), fmt_state!($($y),*))
  );
  ($x:expr) => {{
    let s: String = format!("{:?}", $x).chars().collect();
    let v = &s[8..s.len()-2];
    let mut r = format!("memory: [");
    let mut i = 0;
    for _c in v.chars() {
      if _c == ',' || _c == ' ' {
        continue;
      } else if _c != '0' {
        r = format!("{} {}@{} ", r, _c, i);
      }
      i += 1;
    }
    format!("{}]", r)
  }}
}

// Print elements of config state, i.e. stack, locals, instrs
// Usage ex.:
//    print_config!(stack);
//    print_config!(instrs, stack);
//    etc
#[allow(unused_macros)]
macro_rules! print_config {
  ($x:ident) => (
    println!("{:?}", fmt_state!($x));
  );
  ($x:ident, $($y:ident),*) => (
    println!("{:?}", fmt_state!($x, $($y),*));
  );
}

// Print memory layout. Format is value@index.
// Usage: print_memory!(module.memory);
#[allow(unused_macros)]
macro_rules! print_memory {
  ($x:expr) => (
    println!("{:?}", fmt_state!($x));
  )
}

fn step(module: &mut WModule, config: WConfig) -> WConfig {
  use self::WInstr::*;

  let WConfig {mut locals, mut stack, mut instrs} = config;
  let instr = instrs.remove(0);

  let new_instr = match instr {

    Unreachable => Some(Trapping("Unreachable".to_string())),
    
    Const(n) => { stack.push(n); None },

    // YOUR CODE GOES HERE
    
    Binop(binop) => { match binop {
      Add => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push(n1 + n2);}}; None },
      Sub => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push(n1 - n2);}} None },
      Mul => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push(n1 * n2);}} None },
      DivS => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push(if n2 == 0 {0} else {n1 / n2});}} None }
    } }
    
    Relop(relop) => { match relop {
      Eq => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push((n1 == n2) as i32);}} None },
      Lt => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push((n1 < n2) as i32);}} None },
      Gt => { if let Some(n2) = stack.pop() {if let Some(n1) = stack.pop() {stack.push((n1 > n2) as i32);}} None }
    } }
    
    GetLocal(i) => { if let Some(n) = locals.get(i as usize) {stack.push(*n);} None }
    
    SetLocal(i) => { if let Some(n) = stack.pop() {locals[i as usize] = n;} None}
    
    BrIf(label) => {  match stack.pop() {
      Some(n) => if n == 0 {None} else {Some(Br(label))},
      None => None
    }
    }
    
    Return => { match stack.pop() {
      Some(n) => Some(Returning(n)),
      None => None
    }
    }
    
    Loop(instrs) => { Some(Label{continuation : Box::new(Some(Loop(instrs.clone()))), 
      stack : vec![], instrs: instrs.clone()})
    }
    
    Block(instrs) => { Some(Label{continuation : Box::new(None), stack : vec![],
      instrs: instrs.clone()})
    }
    
    Label{continuation, stack: mut new_stack, instrs: new_instrs} => {
      match new_instrs.clone().pop() {
        None => None,
        Some(ins) => match ins {
          Trapping(n) => Some(Trapping(n)),
          Returning(n) => Some(Returning(n)),
          Br(0) => {Some(continuation.unwrap())},
          Br(i) => Some(Br(i - 1)),
          _ => {let WConfig {mut locals , mut stack, mut instrs} 
                = step(module, WConfig {locals: locals.clone(), stack: new_stack, instrs: new_instrs});
               Some(Label{continuation: continuation, stack: stack, instrs: instrs})}
        }
      }

    }
    
    Call(i) => { unimplemented!(); }
    
    Frame(mut new_config) => { unimplemented!(); }
    
    Load => { match stack.pop() {
      Some(i) => { match module.memory.load(i) {
                  Some(n) => {stack.push(n); None}
                  None => {Some(Trapping("Unreachable".to_string()))}
      } }
      None => None
    } }
    
    Store => { match stack.pop() {
      Some(n) => { match stack.pop() {
        Some(i) => { match module.memory.store(i, n) {
          true => None,
          false => Some(Trapping("Unreachable".to_string()))
         }
        }
        None => None
      } }
      None => None
    } }
    
    Size => { stack.push(module.memory.size()); None }
    
    Grow => { module.memory.grow(); None }
    
    Returning(n) => { Some(Trapping("Unreachable".to_string())) }
    
    Br(n) => { Some(Trapping("Unreachable".to_string())) }
    
    Trapping(n) => unreachable!(),

    // END YOUR CODE

  };

  if let Some(ins) = new_instr {
    instrs.insert(0, ins);
  }

  WConfig {locals, stack, instrs}
}

pub fn interpret(mut module: WModule) -> Result<i32, String> {
  let mut config = WConfig {
    locals: vec![],
    stack: vec![],
    instrs: vec![WInstr::Call(0)]
  };

  while config.instrs.len() > 0 {
    if let WInstr::Trapping(ref err) = &config.instrs[0] {
      return Err(err.clone())
    }
    config = step(&mut module, config);
  }

  Ok(config.stack.pop().unwrap())
}
