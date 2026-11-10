// ERROR esperado: List requiere un argumento de tipo en new List(...).
object List[+A](val item : A)
method main {
  val list = new List(3)
}
