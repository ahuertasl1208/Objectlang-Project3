object Animal
Animal.speak = method(x : Int) : String { "ok" }

method main {
  val a = new Animal {
    override speak(x : Bool) : String = { "incorrect" }
  }
}
