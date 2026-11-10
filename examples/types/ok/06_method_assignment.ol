object Cat
Cat.talk = method() : String {
  println("meow")
  "meow"
}

method main {
  val cat : Cat = new Cat
  cat.talk()
}
