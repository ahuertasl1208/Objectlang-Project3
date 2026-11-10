// ERROR esperado: List[Animal] no es subtipo de List[Dog] con covarianza +A.
object Animal
object Dog extends Animal
object List[+A](val item : A)
method main {
  val animals : List[Animal] = new List[Animal](new Animal)
  val dogs : List[Dog] = animals
}
