# Implementation Plan: Math Library

## Task 1: Create Add Function

Create a simple add function that takes two numbers and returns their sum.

**File:** `src/math.js`

```javascript
export function add(a, b) {
  return a + b;
}
```

**Tests:** Write a test in `test/math.test.js` that verifies:
- `add(1, 2)` returns `3`
- `add(-1, 1)` returns `0`
- `add(0, 0)` returns `0`

**Verification:** `npm test`

## Task 2: Create Multiply Function

Create a multiply function that takes two numbers and returns their product.

**File:** `src/math.js` (add to existing file)

```javascript
export function multiply(a, b) {
  return a * b;
}
```

**Tests:** Add tests to `test/math.test.js` that verify:
- `multiply(2, 3)` returns `6`
- `multiply(-1, 5)` returns `-5`
- `multiply(0, 100)` returns `0`

**Verification:** `npm test`
