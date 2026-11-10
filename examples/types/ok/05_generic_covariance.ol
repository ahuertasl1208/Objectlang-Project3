object Animal
object Dog extends Animal
object List[+A](val item : A)

method main {
  val dogs : List[Dog] = new List[Dog](new Dog)
  val animals : List[Animal] = dogs
}
