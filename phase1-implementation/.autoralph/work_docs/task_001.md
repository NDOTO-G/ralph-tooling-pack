# Task 001: Add Simple Utility Function

## Overview
Create a basic math utility function for testing the Ralph workflow. This is a minimal test task designed to validate that all Ralph components work correctly.

## Technical Requirements
- Create a simple `add` function that takes two numbers and returns their sum
- Write tests using Jest (or your project's test framework)
- Keep it simple - this is just for testing Ralph

## Files to Create

### `src/utils/math.js`
```javascript
/**
 * Add two numbers
 * @param {number} a - First number
 * @param {number} b - Second number
 * @returns {number} Sum of a and b
 */
export function add(a, b) {
  return a + b;
}
```

### `src/utils/math.test.js`
```javascript
import { add } from './math.js';

describe('Math utilities', () => {
  test('adds two positive numbers', () => {
    expect(add(2, 3)).toBe(5);
  });

  test('adds a positive and negative number', () => {
    expect(add(5, -3)).toBe(2);
  });

  test('adds two negative numbers', () => {
    expect(add(-2, -3)).toBe(-5);
  });

  test('adds zero', () => {
    expect(add(0, 5)).toBe(5);
    expect(add(5, 0)).toBe(5);
  });
});
```

## Files to Modify
None - this is a new utility

## Acceptance Criteria
1. `src/utils/math.js` exists with `add` function
2. `src/utils/math.test.js` exists with 4 test cases
3. All tests pass when running `npm test`
4. Files are committed to the branch

## Validation
After implementation, run in the worktree:
```bash
npm test -- math
```

All tests should pass.

## Implementation Notes
- Create the `src/utils` directory if it doesn't exist
- Use ES6 module syntax (import/export)
- Keep functions pure (no side effects)
- Make sure to commit your changes before completing

## Context
This is a Phase 1 test task for validating the Ralph multi-agent system. The simplicity is intentional - we want to test the orchestration workflow, not the complexity of the implementation.

## Expected Outcome
After completion:
- 2 new files created
- 4 tests passing
- 1-2 commits on ralph/task-001 branch
- Clean implementation ready to merge
