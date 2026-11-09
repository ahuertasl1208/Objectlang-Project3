method main {
  val x : Int = 2 + 3 * 4
  val ok = x > 10 and true
  val c : Char = 'z'
  println("x = $x, ok = ${ok}, c = $c")
  println(if x > 100 then "grande" else "pequeno")
  print("sin salto ")
  val s = println("fin")
  println("println devolvio: $s")
}