// ERROR esperado: Ghost no existe, aun dentro de un argumento generico anidado.
object Box[+T](val item : T)
method main {
  val item : Box[Box[Ghost]] = new Box[Box[Ghost]](new Box[Ghost](new Ghost))
}
