(module
  (memory 1)
  (func (result i32) (local i32)
      (block
      (i32.const 4)
      (i32.const 8)
      (i32.store)
      (br 0))
      (i32.const 4)
      (i32.load))
)


    
   