method main {
  val x = 7
  var y : Int = x + 3
  y = y * 2
  val greater : Bool = y > x
  val result : Int = if greater then y else x
  println(result)
}
