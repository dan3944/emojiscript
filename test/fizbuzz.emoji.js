
function fizzbuzz(number) {
  while(number > 0) {

    if (number % 3 == 0) {
      console.log("fizz")
    }
    if (number % 5 == 0) {
      console.log("buzz")
    }
    number--
  }
}

fizzbuzz(20)
