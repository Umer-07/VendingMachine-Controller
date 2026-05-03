# Vending Machine Controller

## Project Overview

This project is a beginner-friendly ASIC/digital design project built in SystemVerilog. It models a simple vending machine controller using finite state machine logic. The machine accepts nickels, dimes, and quarters for a 30-cent product, tracks the inserted amount, dispenses the product when enough money has been entered, and returns change when needed.

## Why I Built This

I built this project to practice digital logic design and verification in a realistic way. A vending machine is simple to understand, but it still requires important engineering concepts like state transitions, input handling, reset behavior, and edge-case testing. This helped me better understand how hardware logic can be designed to make decisions over time.

## Features

- Accepts 5-cent, 10-cent, and 25-cent coin inputs
- Tracks the current inserted amount
- Dispenses product when total reaches 30 cents
- Returns correct change if too much money is inserted
- Resets back to the starting state after dispensing
- Includes testbench verification
- Can be viewed through waveform simulation

## Inputs

| Signal | Description |
|---|---|
| `clk` | Clock signal |
| `reset` | Resets the machine to 0 cents |
| `coin` | Coin input: nickel, dime, or quarter |

## Outputs

| Signal | Description |
|---|---|
| `dispense` | Goes high when product is released |
| `change` | Shows the amount of change returned |

## Coin Encoding

| Coin Input | Meaning |
|---|---|
| `00` | No coin |
| `01` | Nickel, 5 cents |
| `10` | Dime, 10 cents |
| `11` | Quarter, 25 cents |

## FSM States

The controller uses states to represent the amount of money currently inserted:

| State | Amount |
|---|---|
| `S0` | 0 cents |
| `S5` | 5 cents |
| `S10` | 10 cents |
| `S15` | 15 cents |
| `S20` | 20 cents |
| `S25` | 25 cents |

Once the inserted amount reaches or passes 30 cents, the machine dispenses the product and returns to `S0`.

## Example Transactions

### Exact Payment

```text
10 + 10 + 10 = 30
dispense = 1
change = 0
