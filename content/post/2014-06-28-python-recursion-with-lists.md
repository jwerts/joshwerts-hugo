+++
title = "Python: Recursion with Lists"
date = "2014-06-28"
categories = [
  "python"
]
tags = [
  "python",
  "recursion",
  "closure"
]
description = "Fun with recursion in Python - standard problem to test returning a list from a recursive function with closure"
url = "blog/2014/06/28/python-recursion-with-lists/"
+++

I rarely find use cases for recursion in my every day work, but every once in a while, there's a problem that comes up where I instantly think: "Recursion!" (typically followed by an equal mix of excitement and dread).

I often try to get away from GIS related programming when I'm not at work.  With limited free time, Python's the perfect language to focus on fundamentals without getting bogged down with other concerns.

Recursion is challenging enough already but I find it even more difficult to wrap my head around when the end result is intended to be a list.  I love nested functions (and closure) in Python (as long as it doesn't get out of hand) and think it works well in this case to provide the expected simple interface to a function despite the fact that recursion is being used internally.

Most of the code I write for work is proprietary and can't be posted here, so here's a classic problem I've been playing around with simply for learning purposes.

#### Code:
```python
def prime_factors(x):
    """ returns all prime factors of x
    ex:  prime_factors(21) = [3,7]
    ex:  prime_factors(24) = [2,2,2,3]
    """

    def get_first_prime(y):
        """ returns first prime of y """
        # 0 and 1 are not prime, start with 2
        i = 2

        while i <= y:
            if y % i == 0:
                return i
            i += 1

    def get_primes(y, primes):
        """ Recursively appends primes of y
            ex:  prime_factors(24) = [2,2,2,3]

            24
           /  \
          2    12
              /  \
             2    6
                 / \
                2   3

        Appends end nodes of tree as it recurses down.
        """
        first_prime = get_first_prime(y)
        primes.append(first_prime)

        if y == first_prime:
            return

        else:
            # Number is not prime and can be divided further.
            # Divide by the first prime (left node)
            # to get the next test value (right node)
            get_primes(y / first_prime, primes)


    primes = []
    if x >= 2:
        get_primes(x, primes)

    return primes
```

#### Usage:
```python
>>> prime_factors(24)
[2, 2, 2, 3]
>>> prime_factors(13595)
[5, 7, 13, 29]
>>> prime_factors(23049820394)
[2, 89, 139, 181, 5147]
```


The list ```primes``` is passed by reference into the recursive function and simply appended to throughout the operation to keep track of the values.  There is no actual return value from the function.  

This could be difficult to follow if the end user used: ```get_primes(y, primes) -> void``` directly but since it's wrapped in a simpler interface:  ```prime_factors(x) -> primes```, the end result is a returned list as expected.
