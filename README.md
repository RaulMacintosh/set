<p align="center"><img src ="img/set-icon-i.png" width="500px"/></p>

---

## Description

Set is an imperative programming language with a focus on mathematics teaching, therefore, is aimed at teachers and students. The language handles sets as one of the primitive types.

This interpreter for this language is a project of the discipline of Programming Language, Concepts and Paradigms of the Information Technology course of the Federal University of Rio Grande do Norte (UFRN).

### About the interpreter

The interpreter of the set programming language was a homework of the Concepts and Paradigms Programming Language course of the Federal University of Rio Grande do Norte (UFRN). The interpreter was developed using the Haskell language. We used Alex to generate the Haskell lexical analyzer for our language and we used the Parsec library to implement the parser and the interpreter.

#### Compiling

To compile the interpreter use the ```make.sh``` file.

#### Running a program

To run a set program use the following command:

	./set <file-name>

## Learning

A set program has the following structure:

    program <program-name>
        <statements>
    end <program-name>

Hello World in set:

    program helloworld
        print("Hello World!");
    end helloworld

#### Comments:

    program helloworld
        % Comments
        print("Hello World!");
    end helloworld

#### Primitive Data types:

##### Natural

    Nat : x := 1;

##### Integer

    Int : x := 1;
    Int : y := -1;

##### Real

    Real : x := 1.0;
    Real : y := -1.0;

##### Bool

    Bool : x := true;
    Bool : y := false;

##### Text

    Text : x := "Hello world";

##### Array

    % Array[Type,Size] : x;
    Array[Nat,3] : x;
    x[0] := 1;
    x[1] := 2;
    x[2] := 3;
    print("{x[0]=" + x[0] + ",x[1]=" + x[1] + ",x[2]=" + x[2] + "}");

##### Coercion

| Types | Coercion        |
|-------|-----------------|
| Nat   | Int, Real, Text |
| Int   | Real, Text      |
| Real  | Text            |
| Bool  | Text            |
| Text  | -               |
| Array | Text            |

#### Expressions:

##### Arithmetic operations

1. Sum:

        program sum
            Nat : x := 1;
            Int : y;
            y := 1;
            Int sum := x + y; % Result: 2
            print(sum);
        end sum

2. Subtraction:

        program subtraction
            Nat : x := 1;
            Int : y := 1;
            print(x - y); % Result: 0
        end subtraction

3. Multiplication:

        program multiplication
            Real : x := 5.0;
            Int : y := 2;
            print(x * y); % Result: 10.0
        end multiplication

4. Division:

        program division
            Real : x := 10.0;
            Int : y := 2;
            print(x / y); % Result: 5.0
        end division

##### Boolean operations

5. Equality

        program equality
            print(2 == 2); % Result: True
            print(2 == 1); % Result: False
        end equality

6. Conjunction

        program conjunction
            print((1 == 1) && (2 == 2)); % Result: True
            print((1 == 1) && (2 == 1)); % Result: False
            print((2 == 1) && (1 == 1)); % Result: False
            print((2 == 1) && (2 == 1)); % Result: False
        end conjunction

7. Disjunction

        program disjunction
            print((1 == 1) || (2 == 2)); % Result: True
            print((1 == 1) || (2 == 1)); % Result: True
            print((2 == 1) || (1 == 1)); % Result: True
            print((2 == 1) || (2 == 1)); % Result: False
        end disjunction

8. Greater than

        program greaterthan
            print(2 > 1); % Result: True
            print(1 > 2); % Result: False
            print(1 > 1); % Result: False
        end greaterthan

9. Smaller than

        program smallerthan
            print(2 < 1); % Result: False
            print(1 < 2); % Result: True
            print(1 < 1); % Result: False
        end smallerthan

10. Greater than or equal to

        program greaterthanorequal
            print(2 >= 1); % Result: True
            print(1 >= 2); % Result: False
            print(1 >= 1); % Result: True
        end greaterthanorequal

11. Smaller than or equal to

        program smallerthanorequal
            print(2 <= 1); % Result: False
            print(1 <= 2); % Result: True
            print(1 <= 1); % Result: True
        end smallerthanorequal


##### String manipulation operations

12. Concatenation:

        program concat
            Real : x := 2.0;
            Real : y := 2.0;
            Text : s := "of the sum:";
            print("Result " + s + (x + y)); % Result: "Result of the sum: 4.0"
        end concat

#### Condition structure

The only condition structure is the ```if-elseif-else```:

    program conditionstructure
        if (1 > 2)
            print("Something wrong.");
        elseif (2 > 1)
            print("OK.");
        else
            print("Something wrong.");
        endif
    end conditionstructure

#### Repetition structure

The only repetition structure is the ```while```:

    program repetitionstructure
        Nat : count := 0;
        while(count < 10)
            count := count + 1;
            print(count);
        endwhile
    end repetitionstructure

#### Input and Output

    program inputoutput
        Text : t;
        input(t); % Get user input
        print(t); % Print user input
    program inputoutput

### What was planned to implement but not done

- Set type
- Matrix type
- Pointer type
- User types
- Function
- Procedure
- Exit
- Break
- Continue

## Team

[![Breno Viana](https://avatars2.githubusercontent.com/u/17532418?v=3&u=46e9d47c495080fd08dc336d0767f76a57a7644b&s=400)](https://github.com/brenov) | [![Felipe Barbalho](https://avatars2.githubusercontent.com/u/8813353?v=3&s=400)](https://github.com/Barbalho12) | [![Patrícia Cruz](https://avatars2.githubusercontent.com/u/17392686?v=3&s=400)](https://github.com/Pekorishia) | [![Raul Silveira](https://avatars3.githubusercontent.com/u/12190094?v=3&s=400)](https://github.com/RaulMacintosh) | [![Jackson Rauup](https://avatars0.githubusercontent.com/u/17713381?v=3&s=400)](https://github.com/jacksonrauupti)
---|---|---|---|---
[Breno Viana](https://github.com/brenov) | [Felipe Barbalho](https://github.com/Barbalho12) | [Patrícia Cruz](https://github.com/Pekorishia) | [Raul Silveira](https://github.com/RaulMacintosh) | [Jackson Rauup](https://github.com/jacksonrauupti)
