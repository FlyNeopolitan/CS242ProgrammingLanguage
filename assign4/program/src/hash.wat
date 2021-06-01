(module
  (memory 1)
  (export "mem" (memory 0))

  ;; Stack-based Adler32 hash implementation.
  (func $adler32 (param $address i32) (param $len i32) (result i32)
    (local $a i32) (local $b i32) (local $i i32)

    ;; YOUR CODE GOES HERE
    (i32.const 1)
    (set_local $a)
    (i32.const 0)
    (set_local $b)
    (i32.const 0)
    (set_local $i)

    (block $process_end
    (loop $process
    ;; if index >= len, break the loop
    (get_local $i)
    (get_local $len)
    (i32.sub)
    (i32.const 0)
    (i32.ge_s)
    (br_if $process_end)
    ;; assign a
    (get_local $i)
    (get_local $address)
    (i32.add)
    (i32.load8_u)
    (get_local $a)
    (i32.add)
    (i32.const 65521)
    (i32.rem_u)
    (set_local $a)
    ;; assign b
    (get_local $b)
    (get_local $a)
    (i32.add)
    (i32.const 65521)
    (i32.rem_u)
    (set_local $b)
    
    ;; ++index
    (get_local $i)
    (i32.const 1)
    (i32.add)
    (set_local $i)
    (br $process)
    ))

    ;; return (b << 16) | a
    (get_local $b)
    (i32.const 16)
    (i32.shl)
    (get_local $a)
    (i32.or)
    )
  (export "adler32" (func $adler32))

  ;; Tree-based Adler32 hash implementation.
  (func $adler32v2 (param $address i32) (param $len i32) (result i32)
    (local $a i32) (local $b i32) (local $i i32)

    ;; YOUR CODE GOES HERE
    (i32.const 1)
    (set_local $a)
    (i32.const 0)
    (set_local $b)
    (i32.const 0)
    (set_local $i)

    (block $process_end
    (loop $process
    ;; if index >= len, break the loop
    (i32.ge_s
      (i32.sub (get_local $i) (get_local $len)) (i32.const 0))
    (br_if $process_end)
    ;; assign a
    (i32.rem_u 
        (i32.add
          (get_local $a)
          (i32.load8_u
            (i32.add (get_local $i) (get_local $address))))
        (i32.const 65521))
    (set_local $a)
    ;; assign b
    (i32.rem_u 
      (i32.add (get_local $a) (get_local $b))
      (i32.const 65521))
    (set_local $b)
    
    ;; ++index 
    (i32.add (get_local $i) 
             (i32.const 1))
    (set_local $i)
    (br $process)
    ))

    ;; return (b << 16) | a
    (i32.or (i32.shl (get_local $b) (i32.const 16)) 
            (get_local $a))
    )

  (export "adler32v2" (func $adler32v2))

  ;; Initialize memory allocator. Creates the initial block assuming memory starts with
  ;; 1 page.
  (func $alloc_init
    (i32.store (i32.const 0) (i32.const 65528))
    (i32.store (i32.const 4) (i32.const 1)))
  (export "alloc_init" (func $alloc_init))

  ;; Frees a memory block by setting the free bit to 1.
  (func $free (param $address i32)
    (i32.store
      (i32.sub (get_local $address) (i32.const 4))
      (i32.const 1)))
  (export "free" (func $free))

  (func $alloc (param $len i32) (result i32)
    (local $addr i32) (local $cur_len i32) (local $nextblock i32)
    ;; initialize
    (i32.const 0)
    (set_local $addr)
    (block $process_end
    (loop $process
    ;; Critical failure if we're out of memory
    (i32.ge_s (get_local $addr) (i32.const 65536))
    (br_if $process_end)
    ;; cur_len = load(addr);
    (i32.load (get_local $addr))
    (set_local $cur_len)
    ;;  Use the current block if it's free and log enough
    (if $check
     (i32.and (i32.eq (i32.load (i32.add (get_local $addr) (i32.const 4)))
                      (i32.const 1))
              (i32.ge_s (get_local $cur_len) (get_local $len))
     )
     (then (i32.store (i32.add (get_local $addr) (i32.const 4)) (i32.const 0))
           (if $enough
            (i32.ge_s (get_local $cur_len) (i32.add (get_local $len) (i32.const 8)))
            (then (i32.store (get_local $addr) (get_local $len))
                  (i32.add (get_local $addr) (i32.add (get_local $len) (i32.const 8)))
                  (set_local $nextblock)
                  (i32.store (i32.add (get_local $nextblock) (i32.const 4)) (i32.const 1))
                  (i32.store (get_local $nextblock) 
                             (i32.sub (get_local $cur_len)
                                      (i32.add (get_local $len) (i32.const 8))))
            )
            (else (i32.add (get_local $addr) (i32.const 8))
                  (return))
           )
           (i32.add (get_local $addr) (i32.const 8))
           (return)
     )
     (else
      ;;addr = addr + 8 + cur_len
      (i32.add (get_local $addr) (i32.add (get_local $cur_len) (i32.const 8)))
      (set_local $addr)
     )
    )
    (br $process)
    ))
    ;;rasie an error
    (i32.const -1)
    )
  (export "alloc" (func $alloc))

  )
