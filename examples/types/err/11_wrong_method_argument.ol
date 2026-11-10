object Counter
Counter.add = method(amount : Int) : Int { amount }

method main {
  val counter : Counter = new Counter
  counter.add(true)
}
