# FIFO DV Test Plan (Directed + Scoreboard)

## DUT Summary
- Parameterized synchronous FIFO (WIDTH, DEPTH)
- Active-low synchronous reset (rst_n)
- push/pop handshake
- full/empty status flags
- Registered dout (read data is clocked out)
- count output for debug/visibility

## Verification Strategy
Directed tests + a reference (golden) model:
- Reference model uses a circular buffer + count
- Scoreboard compares:
  - dout vs expected data on successful pop
  - empty/full vs reference count

## Tests
1. Reset behavior
   - Expect empty=1, full=0, ref_count=0
2. Fill to full
   - Push DEPTH items, expect full=1
3. Overflow attempt
   - Push when full should be ignored (no ref_count change)
4. Drain to empty
   - Pop DEPTH items, expect empty=1
5. Underflow attempt
   - Pop when empty should be ignored (no ref_count change)
6. Wraparound stress
   - Push/pop pattern > DEPTH to force pointer rollover
7. Simultaneous push+pop
   - Verify stable behavior with same-cycle transactions (when not full/empty)

## Pass Criteria
- No $fatal triggers
- Scoreboard checks pass for:
  - data ordering
  - empty/full correctness
