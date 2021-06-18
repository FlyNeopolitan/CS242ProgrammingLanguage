use std::mem;
use std::sync::{mpsc, Mutex, Arc};
use std::thread;
use future::{Future, Poll};
use future_util::*;

/*
 * Core executor interface.
 */

pub trait Executor {
  fn spawn<F>(&mut self, f: F)
  where
    F: Future<Item = ()> + 'static;
  fn wait(&mut self);
}


/*
 * Example implementation of a naive executor that executes futures
 * in sequence.
 */

pub struct BlockingExecutor;

impl BlockingExecutor {
  pub fn new() -> BlockingExecutor {
    BlockingExecutor
  }
}

impl Executor for BlockingExecutor {
  fn spawn<F>(&mut self, mut f: F)
  where
    F: Future<Item = ()>,
  {
    loop {
      if let Poll::Ready(()) = f.poll() {
        break;
      }
    }
  }

  fn wait(&mut self) {}
}

/*
 * Part 2a - Single threaded executor
 */

pub struct SingleThreadExecutor {
  futures: Vec<Box<Future<Item = ()>>>,
}

impl SingleThreadExecutor {
  pub fn new() -> SingleThreadExecutor {
    SingleThreadExecutor { futures: vec![] }
  }
}

impl Executor for SingleThreadExecutor {
  fn spawn<F>(&mut self, mut f: F)
  where
    F: Future<Item = ()> + 'static,
  {
    if let Poll::NotReady = f.poll() {
      self.futures.push(Box::new(f));
    }
  }

  fn wait(&mut self) {
    for fut in self.futures.iter_mut() {
      loop {
        if let Poll::Ready(_) = fut.poll() {
          break;
        }
      }
    }
  }
}

pub struct MultiThreadExecutor {
  sender: mpsc::Sender<Option<Box<Future<Item = ()>>>>,
  threads: Vec<thread::JoinHandle<()>>,
}


impl MultiThreadExecutor {
  pub fn new(num_threads: i32) -> MultiThreadExecutor {
    let mut threads = vec![];
    let (sender, receiver) = mpsc::channel();
    for i in 0..num_threads {
      let currSender = sender.clone();
      let t = thread::spawn(move || { 
        let mut currThread = SingleThreadExecutor::new();
        loop {
          let message = receiver.recv().unwrap();
          match message {
            None => {
              currThread.wait();
              break;
            }
            Some(fut) => {
              currThread.spawn(fut)
            }
          }
        } 
      });
      threads.push(t);
    }

    MultiThreadExecutor{
      sender: sender,
      threads: threads
    }
  }
}

impl Executor for MultiThreadExecutor {
  fn spawn<F>(&mut self, f: F)
  where
    F: Future<Item = ()> + 'static,
  {
    self.sender.send(Some(Box::new(f)));
  }

  fn wait(&mut self) {
    self.sender.send(None);
    for handle in &self.threads {
      unsafe {
        let h = std::ptr::read(handle);
        h.join().unwrap();
      }
    }
  }
}
