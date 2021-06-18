extern crate rand;

use session::*;
use std::collections::{HashSet, HashMap};

pub struct Syn;
pub struct SynAck;
pub struct Ack;
pub struct Fin;

pub type TCPHandshake<TCPRecv> = Recv<Syn, Send<SynAck, Recv<Ack, TCPRecv>>>;

pub type TCPRecv<TCPClose> = Rec<Recv<Vec<Packet>, Send<Vec<usize>, Offer<TCPClose, Var<Z>>>>>;

pub type TCPClose = Send<Ack, Send<Fin, Recv<Ack, Close>>>;

pub type TCPServer = TCPHandshake<TCPRecv<TCPClose>>;

pub type TCPClient = <TCPServer as HasDual>::Dual;

pub fn tcp_server(c: Chan<(), TCPServer>) -> Vec<Buffer> {
  //Handshake Period
  let mut results = Vec::new();
  let (c, Syn) = c.recv();
  let c = c.send(SynAck);
  let (c, Ack) = c.recv();
  
  let mut tags = HashMap::new();
  
  //Data transfer Period
  let mut c = c.rec_push();
  loop {
    c = {
      let (c, Packets) = c.recv();
      for packet in Packets.iter() { //store received items
        results.push(packet.buf.clone());
        tags.insert(packet.seqno, packet.buf.clone());
      }
      let c = c.send(Packets.iter().map(|x| x.seqno).collect());
      match c.offer() {
        Branch::Left(c) => { //enter Close state
          let c = c.send(Ack);
          let c = c.send(Fin);
          let (c, Ack) = c.recv();
          c.close();
          for i in tags.keys() {
            match tags.get(i) {
              None => {}
              Some(item) => {results[*i] = item.to_vec()}
            }
          }
          return results;
        }
        Branch::Right(c) => { //continue receiving (re-enter data transfer Period)
          c.rec_pop()
        }
      }
    }
  }
}

pub fn tcp_client(c: Chan<(), TCPClient>, bufs: Vec<Buffer>) {
  //Handshake Period
  let c = c.send(Syn);
  let (c, SynAck) = c.recv();
  let c = c.send(Ack);
  let mut c = c.rec_push();
  
  let mut remains = HashSet::new(); //record items needed to send
  for i in 0..bufs.len() {
    remains.insert(i);
  }
  //Data transfer Period
  loop {
    c = {
      let c = c.send(bufs.iter().enumerate().filter(|(pos, x)| remains.contains(pos))
        .map(|(pos, x)| Packet{buf: x.to_vec(), seqno: pos}).collect()); //send remaining items
      let (c, got) = c.recv();
      for item in got.iter() {
        remains.remove(item); 
      }
      if remains.is_empty() { //no items need to send, enter Close state
        let c = c.left();
        let (c, Ack) = c.recv();
        let (c, Fin) =  c.recv();
        let c = c.send(Ack);  
        let c = c.close();
        return
      }
      let c = c.right(); //Else, re-enter data transfer state
      c.rec_pop()
    }
  }
}

#[cfg(test)]
mod test {
  use session::*;
  use session::NOISY;
  use std::sync::atomic::Ordering;
  use rand;
  use rand::Rng;
  use tcp::*;
  use std::marker::PhantomData;
  use std::sync::mpsc::channel;
  use std::thread;

  fn gen_bufs() -> Vec<Buffer> {
    let mut bufs: Vec<Buffer> = Vec::new();
    let mut rng = rand::thread_rng();
    for _ in 0usize..20 {
      let buf: Buffer = vec![0; rng.gen_range(1, 10)];
      let buf: Buffer = buf.into_iter().map(|x: u8| rng.gen()).collect();
      bufs.push(buf);
    }
    bufs
  }

  #[test]
  fn test_basic() {
    let bufs = gen_bufs();
    let bufs_copy = bufs.clone();
    let (s, c): ((Chan<(), TCPServer>), (Chan<(), TCPClient>)) = Chan::new();
    let thread = thread::spawn(move || { tcp_client(c, bufs); });

    let recvd = tcp_server(s);
    let res = thread.join();

    assert_eq!(recvd, bufs_copy);
  }

  #[test]
  fn test_lossy() {
    let bufs = gen_bufs();
    let bufs_copy = bufs.clone();

    NOISY.with(|noisy| {
      noisy.store(true, Ordering::SeqCst);
    });

    let (s, c): ((Chan<(), TCPServer>), (Chan<(), TCPClient>)) = Chan::new();
    let thread = thread::spawn(move || { tcp_client(c, bufs); });

    let recvd = tcp_server(s);
    let res = thread.join();

    assert_eq!(recvd, bufs_copy);
  }
}
