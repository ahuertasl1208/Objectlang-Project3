method main {
  val a = 7
  val b = 3
  val max = if a > b then a else b
  println("max = $max")
  for (rating <- 1 -> 3) println(" Movie : Objectilang , Rating : $rating ")
}