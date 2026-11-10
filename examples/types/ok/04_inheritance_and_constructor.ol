object Animal
object Dog extends Animal
object Box(val pet : Animal)

method main {
  val dog : Dog = new Dog
  val animal : Animal = dog
  val box : Box = new Box(dog)
}
