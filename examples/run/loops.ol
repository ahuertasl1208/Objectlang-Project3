method main {
  var total = 0
  for (i <- 1 -> 4) total = total + i
  println("total = $total")
  for (i in 1 -> 3) println("i = $i")
  println("${3 in (1 -> 5)} ${7 in (1 -> 5)}")
  var x = 1
  x = x * 10
  println("x = $x")
}