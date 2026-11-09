object Animal
object Cat extends Animal

Cat. talk = method () : String {
 print (" Cats meows ")
}

method main {
  val c = new Cat
  c.talk()
}